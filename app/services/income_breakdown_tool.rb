# frozen_string_literal: true

class IncomeBreakdownTool < RubyLLM::Tool
  description 'Generates income breakdown by buyer (client) as pie/donut chart data. ' \
              'Use this when user asks about income by client, revenue distribution, or top clients.'

  param :year, type: :integer, desc: 'Year to filter e.g. 2025. If omitted uses all data.', required: false

  def initialize(user)
    @user = user
  end

  def execute(year: nil)
    scope = @user.invoices.where(self_issued_invoice: [false, nil])
    scope = scope.where('EXTRACT(YEAR FROM issue_date) = ?', year) if year

    data = scope
           .joins("INNER JOIN entities ON entities.invoice_id = invoices.id
              AND entities.entity_type = 'buyer'")
           .group("COALESCE(NULLIF(entities.entity_name, ''),
              entities.first_name || ' ' || entities.last_name)")
           .sum('invoices.total_price_without_tax + invoices.total_tax_amount_eur')
           .sort_by { |_, v| -v }
           .first(8)
           .to_h

    return { error: 'Žiadne dáta o príjmoch.' } if data.empty?

    colors = %w[#6366f1 #22c55e #f59e0b #ef4444 #3b82f6 #ec4899 #14b8a6 #f97316]

    {
      chart_type: 'income_pie',
      title: year ? "Príjmy podľa klienta (#{year})" : 'Príjmy podľa klienta (celkovo)',
      labels: data.keys,
      data: data.values.map { |v| v.to_f.round(2) },
      colors: data.keys.each_with_index.map { |_, i| colors[i % colors.size] }
    }.to_json
  rescue StandardError => e
    Rails.logger.error "IncomeBreakdownTool error: #{e.message}"
    { error: 'Nepodarilo sa načítať dáta o príjmoch.' }.to_json
  end
end
