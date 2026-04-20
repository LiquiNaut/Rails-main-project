require 'ruby_llm'
require 'dotenv/load'

RubyLLM.configure do |config|
  config.openrouter_api_key     = ENV.fetch('OPENROUTER_API_KEY', nil)
  config.openai_api_key         = ENV.fetch('OPENAI_API_KEY', nil)

  config.default_embedding_model = 'text-embedding-3-small'
  config.log_level = :warn
end
