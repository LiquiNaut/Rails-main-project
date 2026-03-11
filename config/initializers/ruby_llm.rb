require 'ruby_llm'
require 'dotenv/load'

RubyLLM.configure do |config|
  # config.openai_api_key = ENV['OPENAI_API_KEY']
  config.openrouter_api_key = ENV['OPENROUTER_API_KEY']
end