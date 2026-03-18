require 'ruby_llm'
require 'dotenv/load'

RubyLLM.configure do |config|
  config.openrouter_api_key     = ENV['OPENROUTER_API_KEY']
  config.openai_api_key         = ENV['OPENAI_API_KEY']

  config.default_embedding_model = 'text-embedding-3-small'
end