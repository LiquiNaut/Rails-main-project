class CreateBankDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :bank_details do |t|
      t.string :bank_name
      t.string :iban
      t.string :swift
      t.string :var_symbol
      t.string :konst_symbol
      t.references :invoice, foreign_key: true, null: false

      t.timestamps
    end
  end
end
