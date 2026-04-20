class EmbeddingJob < ApplicationJob
  queue_as :default

  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    return unless invoice

    vector = EmbeddingService.embed(invoice.embedding_text)
    return unless vector

    # Prevent large embedding vectors from being written to the log.
    # Silence the logger briefly while persisting the vector.
    Rails.logger.silence do
      invoice.update_columns(embedding: vector)
    end

    Rails.logger.info "Embedding uložený pre faktúru ##{invoice_id}"
  end
end
