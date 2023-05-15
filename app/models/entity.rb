# frozen_string_literal: true
class Entity < ApplicationRecord
  belongs_to :invoice

  # Validácie a ďalšie metódy pre model Entity
  enum entity_type: {
    seller: 'seller',
    buyer: 'buyer',
    tax_representative: 'tax_representative'
  }

  def full_name
    "#{first_name} #{last_name}"
  end
end
