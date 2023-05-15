# frozen_string_literal: true

class Invoice < ApplicationRecord
  belongs_to :user
  has_many :entities, class_name: "Entity", dependent: :destroy
  has_one :bank_detail, class_name: "BankDetail", dependent: :destroy
  accepts_nested_attributes_for :entities, :bank_detail

  def seller
    self.entities.seller.first
  end

  def buyer
    self.entities.buyer.first
  end

  def tax_representative
    self.entities.tax_representative.first
  end
end
