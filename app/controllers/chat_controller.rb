require 'ruby_llm'
require 'dotenv/load'

class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    session[:chat_history] ||= []
    @chat_history = session[:chat_history]
  end

  def ask
    user_message = params[:prompt] || params[:message]

    session[:chat_history] ||= []
    session[:chat_history] << { role: 'user', content: user_message }

    detect_intent = XIntentClassifier.classify(user_message)
    Rails.logger.info "Správa: #{user_message.inspect}, Detekovaný zámer: #{detect_intent}"

    begin
      case detect_intent
      when :sql_query
        generator = SqlGenerator.new
        sql_query = generator.generate_sql(user_message)
        Rails.logger.info "Vygenerovaný SQL dotaz: #{sql_query}"

        # TODO: dorobit vykonanie sql dotazu
        assistant_message = "Na základe vašej požiadavky som vygeneroval nasledujúci SQL dotaz:\n\n```#{sql_query}```\n\n"

      when :knowledge_request
        # Špecificka logika pre knowledge_request, napr. RAG



      when :general_chat
        chat = RubyLLM.chat
        response = chat.ask(user_message)
        assistant_message = response.content

      else
        Rails.logger.warn "Neznámy alebo nespracovaný zámer: #{detect_intent}"
        chat = RubyLLM.chat
        response = chat.ask(user_message)
        assistant_message = response.content
      end


      session[:chat_history] << { role: 'assistant', content: assistant_message }
      render json: { response: assistant_message }

    rescue ::SqlGenerator::Error => e
      Rails.logger.error "Chyba pri generovaní SQL: #{e.message}\n#{e.backtrace.join("\n")}"
      error_message = "Nastala chyba pri generovaní SQL dotazu: #{e.message}"
      session[:chat_history] << { role: 'assistant', content: error_message }
      render json: { response: error_message }, status: :internal_server_error
    rescue RubyLLM::Error => e
      Rails.logger.error "Chyba pri komunikácii s LLM: #{e.message}\n#{e.backtrace.join("\n")}"
      error_message = "Ospravedlňujeme sa, nastala chyba pri komunikácii s AI: #{e.message}"
      session[:chat_history] << { role: 'assistant', content: error_message }
      render json: { response: error_message }, status: :internal_server_error
    rescue => e
      Rails.logger.error "Všeobecná chyba v ChatController#ask: #{e.message}\n#{e.backtrace.join("\n")}"
      error_message = "Ospravedlňujeme sa, nastala neočakávaná chyba."
      session[:chat_history] << { role: 'assistant', content: error_message }
      render json: { response: error_message }, status: :internal_server_error
    end
  end
end