# frozen_string_literal: true

class Invoice < ApplicationRecord
  belongs_to :user

  validates :ico, presence: true
  # validates :dic
  # validates :first_name
  # validates :last_name
  # validates :entity_name
  # validates :street
  # validates :street_note
  # validates :city
  # validates :postal_code
  # validates :country
end
