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
        Ak požiadavka nesúvisí so zobrazením dát z databázy, odpovedz priamo.
      SYS

      chat_record
        .with_instructions(system_instructions, replace: true)
        .with_temperature(0.0)
        .with_tool(SqlGeneratorTool.new)

      assistant_response = chat_record.ask(user_message, with: { max_tokens: 200 })

      render json: { response: assistant_response.content }

    rescue ::SqlGeneratorTool::Error => e
      Rails.logger.error "Chyba pri generovaní SQL: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { response: "⚠️ Nastala chyba pri generovaní SQL dotazu: #{e.message}" }, status: :ok

    rescue RubyLLM::Error => e
      Rails.logger.error "Chyba pri komunikácii s LLM: #{e.message}\n#{e.backtrace.join("\n")}"

      user_facing_message = case e.message
      when /quota|billing|exceeded/i
        "⚠️ Prekročená kvóta OpenAI API. Skontroluj fakturáciu na platform.openai.com."
      when /invalid_api_key|Unauthorized|authentication/i
        "⚠️ Neplatný API kľúč. Skontroluj konfiguráciu aplikácie."
      when /rate_limit|too many requests/i
        "⚠️ Príliš veľa požiadaviek. Skúste to znova o chvíľu."
      when /timeout|timed out/i
        "⚠️ Požiadavka vypršala. Skúste to znova."
      when /context_length|maximum context/i
        "⚠️ Konverzácia je príliš dlhá. Začni novú konverzáciu."
      else
        "⚠️ Nastala chyba pri komunikácii s AI. Skúste to znova."
      end

      render json: { response: user_facing_message }, status: :ok

    rescue => e
      Rails.logger.error "Všeobecná chyba v ChatController#ask: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { response: "⚠️ Nastala neočakávaná chyba. Skúste to znova." }, status: :ok
    end
  end
end
