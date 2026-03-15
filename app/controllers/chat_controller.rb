require 'ruby_llm'
require 'dotenv/load'

class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    @chats = current_user.chats.order(created_at: :desc)
    @chat_record = @chats.first
    @chat_history = @chat_record ? @chat_record.messages.order(:created_at) : []
  end

  def show
    @chats = current_user.chats.order(created_at: :desc)
    @chat_record = current_user.chats.find(params[:id])
    @chat_history = @chat_record.messages.order(:created_at)
    render :index
  end

  def new
    chat = Chat.create!(user: current_user, model: 'openai/gpt-4o-mini')
    redirect_to chat_show_path(chat)
  end

  def destroy
    chat = current_user.chats.find(params[:id])
    chat.destroy
    redirect_to chat_path
  end

  def ask
    user_message = params[:prompt] || params[:message]
    chat_id = params[:chat_id]

    chat_record = chat_id.present? ? current_user.chats.find(chat_id) : current_user.chats.last
    chat_record ||= Chat.create!(user: current_user, model: 'openai/gpt-4o-mini')

    begin
      system_instructions = <<~SYS.strip
        Si priateľský asistent (FinanceGPT) pre správu faktúr.
        Pri požiadavkách na zobrazenie dát z databázy použi nástroj 'sql_generator_tool'
        a databázovú schému: #{SqlGeneratorTool.invoice_model_schema}.
        Pri požiadavkách na zobrazenie grafov použi nástroje 'cashflow_chart' alebo 'income_breakdown'.

        DÔLEŽITÉ PRAVIDLÁ PRE GRAFY:
        - Po zavolaní chart nástroja frontend AUTOMATICKY zobrazí interaktívny graf.
        - NIKDY negeneruj obrázky, base64 dáta ani markdown obrázky (![...]).
        - Po zavolaní chart nástroja napíš IBA krátky textový súhrn (max 2-3 vety s kľúčovými číslami).
        - Nepopisuj štruktúru grafu, farby ani technické detaily.

        Ak požiadavka nesúvisí so zobrazením dát z databázy ani s grafmi, odpovedz priamo.
      SYS

      chat_record
        .with_instructions(system_instructions, replace: true)
        .with_temperature(0.0)
        .with_tool(SqlGeneratorTool.new)
        .with_tool(CashflowChartTool.new(current_user))
        .with_tool(IncomeBreakdownTool.new(current_user))

      assistant_response = chat_record.ask(user_message, with: { max_tokens: 200 })

      chart_data = extract_chart_data(chat_record)
      render json: { response: assistant_response.content, chart_data: chart_data }, status: :ok
    rescue ::SqlGeneratorTool::Error => e
      Rails.logger.error "Chyba pri generovaní SQL: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { response: "⚠️ Nastala chyba pri generovaní SQL dotazu: #{e.message}" }, status: :ok
    rescue RubyLLM::Error => e
      Rails.logger.error "Chyba pri komunikácii s LLM: #{e.message}\n#{e.backtrace.join("\n")}"

      user_facing_message = case e.message
                            when /quota|billing|exceeded/i
                              '⚠️ Prekročená kvóta OpenAI API. Skontroluj fakturáciu na platform.openai.com.'
                            when /invalid_api_key|Unauthorized|authentication/i
                              '⚠️ Neplatný API kľúč. Skontroluj konfiguráciu aplikácie.'
                            when /rate_limit|too many requests/i
                              '⚠️ Príliš veľa požiadaviek. Skúste to znova o chvíľu.'
                            when /timeout|timed out/i
                              '⚠️ Požiadavka vypršala. Skúste to znova.'
                            when /context_length|maximum context/i
                              '⚠️ Konverzácia je príliš dlhá. Začni novú konverzáciu.'
                            else
                              '⚠️ Nastala chyba pri komunikácii s AI. Skúste to znova.'
                            end

      render json: { response: user_facing_message }, status: :ok
    rescue StandardError => e
      Rails.logger.error "Všeobecná chyba v ChatController#ask: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { response: '⚠️ Nastala neočakávaná chyba. Skúste to znova.' }, status: :ok
    end
  end

  private

  def extract_chart_data(chat_record)
    last_user_msg = chat_record.messages.where(role: 'user').order(:created_at).last
    return nil unless last_user_msg

    msg = chat_record.messages
                     .where(role: 'tool')
                     .where('created_at > ?', last_user_msg.created_at)
                     .reorder(created_at: :desc)
                     .find do |m|
                       next if m.content.blank?

                       parsed = begin
                         JSON.parse(m.content)
                       rescue StandardError
                         nil
                       end
                       parsed.is_a?(Hash) && parsed['chart_type'].present?
                     end

    return nil unless msg

    begin
      JSON.parse(msg.content)
    rescue StandardError
      nil
    end
  end
end
