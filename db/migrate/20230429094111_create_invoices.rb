class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.string "ico"
      t.string "dic"
      t.string "first_name"
      t.string "last_name"
      t.string "entity_name"

      t.string "street" #ulica
      t.string "street_note" #building number, popisne cislo
      t.string "city" #municipality_id, mesto
      t.string "postal_code" #PSC
      t.string "country" #krajina

      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
