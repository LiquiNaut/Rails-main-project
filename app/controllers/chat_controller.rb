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

    detect_intent = IntentClassifier.classify(user_message)
    Rails.logger.info "Správa: #{user_message.inspect}, Detekovaný zámer: #{detect_intent}"


    chat = RubyLLM.chat
    begin
      response = chat.ask(user_message)
      assistant_message = response.content
      session[:chat_history] << { role: 'assistant', content: assistant_message }
      render json: { response: assistant_message }
    rescue => e
      session[:chat_history] << { role: 'assistant', content: e.message }
      render json: { response: e.message }, status: :internal_server_error
    end
  end
end