class EmbeddingJob < ApplicationJob
  queue_as :default

  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    return unless invoice

    vector = EmbeddingService.embed(invoice.embedding_text)
    return unless vector

    invoice.update_columns(embedding: vector)
    Rails.logger.info "Embedding uložený pre faktúru ##{invoice_id}"
  end
end
