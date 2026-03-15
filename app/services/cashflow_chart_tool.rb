# frozen_string_literal: true

class CashflowChartTool < RubyLLM::Tool
  description 'Generates monthly cashflow chart data for the current user. ' \
              'Use this when user asks for cashflow chart, income/expense overview, or financial trends.'

  param :months, type: :integer, desc: 'Number of past months to include, default 12', required: false

  def initialize(user)
    @user = user
  end

  def execute(months: 12)
    start_date = months.to_i.months.ago.beginning_of_month
    invoices   = @user.invoices.where('issue_date >= ?', start_date)

    all_months = (months.to_i - 1).downto(0)
                                  .map { |i| i.months.ago.to_date.beginning_of_month }
                                  .reverse

    income_by_month  = Hash.new(0.0)
    expense_by_month = Hash.new(0.0)

    invoices.each do |inv|
      next unless inv.issue_date

      key = inv.issue_date.to_date.beginning_of_month
      amount = inv.total_price_without_tax.to_f + inv.total_tax_amount_eur.to_f
      inv.self_issued_invoice? ? expense_by_month[key] += amount : income_by_month[key] += amount
    end

    {
      chart_type: 'cashflow_bar',
      title: "Cashflow za posledných #{months} mesiacov",
      labels: all_months.map { |d| d.strftime('%-m/%Y') },
      datasets: [
        { label: 'Príjmy',  data: all_months.map { |d| income_by_month[d].round(2) },  color: '#22c55e' },
        { label: 'Výdavky', data: all_months.map { |d| expense_by_month[d].round(2) }, color: '#ef4444' }
      ]
    }.to_json
  rescue StandardError => e
    Rails.logger.error "CashflowChartTool error: #{e.message}"
    { error: 'Nepodarilo sa načítať cashflow dáta.' }.to_json
  end
end
