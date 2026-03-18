class EmbeddingService
  def self.embed(text)
    return nil if text.blank?

    result = RubyLLM.embed(text)
    result.vectors
  rescue RubyLLM::Error => e
    Rails.logger.error "EmbeddingService chyba: #{e.message}"
    nil
  end
end
