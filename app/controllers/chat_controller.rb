require 'ruby_llm'
require 'dotenv/load'

class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    @chat_record = current_user.chats.last
    @chat_history = @chat_record ? @chat_record.messages.order(:created_at) : []
  end

  def ask
    user_message = params[:prompt] || params[:message]
    tool_call_id = params[:tool_call_id]

    # Get or create the chat record from the database
    Rails.logger.debug "Current user: #{current_user.inspect}"
    chat_record = current_user.chats.last

    if chat_record.nil?
      chat_record = Chat.create!(
        user: current_user,
        model_id: 'gpt-4o-mini',
        content: '' # TODO: rozmyslam ze by som to zmenil na pocet sprav v danom chate, kedze obsah sprav viem pozriet v db
      )
    end

    # detect_intent = XIntentClassifier.classify(user_message)
    # Rails.logger.info "Správa: #{user_message.inspect}, Detekovaný zámer: #{detect_intent}"

    begin
      system_instructions = <<~SYS.strip
        Si priateľský asistent (FinanceGPT) pre správu faktúr. 
        Pri požiadavkách na zobrazenie dát z databázy použi nástroj 'sql_generator_tool' a databázovú schému: #{SqlGeneratorTool.invoice_model_schema}".
        Ak požiadavka nesúvisí so zobrazením dát z databázy, odpovedz priamo.
      SYS

      # Create a new RubyLLM chat instance first
      llm_chat = RubyLLM.chat(model: chat_record.model_id)
                        .with_instructions(system_instructions)
                        .with_temperature(0.0)
                        .with_tool(SqlGeneratorTool.new)

      llm_chat.on_new_message do
        puts "Asistent píše..."
      end

      # SPRAVNY POSTUP ???? avsak nastava problem: act_as_chat's method, is attempting to create `Message` records without setting the `user_id`
      # chat_record.with_instructions(system_instructions)
      #            .with_temperature(0.0)
      #            .with_tool(SqlGeneratorTool.new)
      #
      # chat_record.on_new_message do
      #   puts "Asistent píše..."
      # end

      # Get the response from the LLM
      assistant_response = llm_chat.ask(user_message, with: { max_tokens: 200 })
      # assistant_response = chat_record.ask(user_message, with: { max_tokens: 200 })

      # create the user message records in the database
      user_msg = chat_record.messages.create!(
        user: current_user,
        role: "user",
        content: user_message,
        model_id: chat_record.model_id,
        input_tokens: assistant_response.input_tokens,
        output_tokens: 0,
        tool_call_id: tool_call_id  # TODO: fixme
      )

      # TODO: fixme
      # tool_call = chat_record.tool_calls.create!(
      #   message_id: user_msg.id,
      #   tool_call_id: tool_call.id,
      #   tool_name: tool_call.name,
      #   arguments: tool_call.arguments || {},
      #   output: tool_call.respond_to?(:output) ? tool_call.output : {},
      #   success: true
      # )


      # create the assistant message records in the database
      assistant_msg = chat_record.messages.create!(
        user: current_user,
        role: "assistant",
        content: assistant_response.content,
        model_id: chat_record.model_id,
        input_tokens: 0,
        output_tokens: assistant_response.output_tokens,
        tool_call_id: tool_call_id # TODO: fixme
      )

      render json: { response: assistant_response.content }

    rescue ::SqlGeneratorTool::Error => e
      Rails.logger.error "Chyba pri generovaní SQL: #{e.message}\n#{e.backtrace.join("\n")}"
      error_message = "Nastala chyba pri generovaní SQL dotazu: #{e.message}"
      render json: { response: error_message }, status: :internal_server_error
    rescue RubyLLM::Error => e
      Rails.logger.error "Chyba pri komunikácii s LLM: #{e.message}\n#{e.backtrace.join("\n")}"
      error_message = "Ospravedlňujeme sa, nastala chyba pri komunikácii s AI: #{e.message}"
      render json: { response: error_message }, status: :internal_server_error
    rescue => e
      Rails.logger.error "Všeobecná chyba v ChatController#ask: #{e.message}\n#{e.backtrace.join("\n")}"
      error_message = "Ospravedlňujeme sa, nastala neočakávaná chyba."
      render json: { response: error_message }, status: :internal_server_error
    end
  end
end