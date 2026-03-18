# frozen_string_literal: true

class Invoice < ApplicationRecord
  has_neighbors :embedding

  belongs_to :user
  has_many :entities, class_name: 'Entity', dependent: :destroy
  has_one :bank_detail, class_name: 'BankDetail', dependent: :destroy
  accepts_nested_attributes_for :entities, :bank_detail

  after_save :schedule_embedding, if: :needs_embedding_update?

  def embedding_text
    [
      "Faktúra: #{invoice_name}",
      "Typ produktu: #{product_type.presence || 'neuvedený'}",
      "Informácie o vozidle: #{vehicle_information.presence || 'žiadne'}"
    ].join('. ')
  end

  def seller
    entities.seller.first
  end

  def buyer
    entities.buyer.first
  end

  def tax_representative
    entities.tax_representative.first
  end

  private

  def needs_embedding_update?
    saved_change_to_invoice_name? ||
      saved_change_to_product_type? ||
      saved_change_to_vehicle_information?
  end

  def schedule_embedding
    EmbeddingJob.perform_later(id)
  end
end
