class CreateEntities < ActiveRecord::Migration[7.0]
  def change
    create_table :entities do |t|
      t.string :entity_name # názov spoločnosti alebo živnostníka
      t.string :entity_type # typ spoločnosti alebo živnostníka
      t.string :first_name # krstné meno
      t.string :last_name # priezvisko
      t.string :street # ulica
      t.string :street_note # číslo domu, bytu
      t.string :city # mesto
      t.string :postal_code # PSČ
      t.string :country # krajina
      t.string :ico # IČO
      t.string :dic # DIČ
      t.string :ic_dph # IČ DPH
      t.references :invoice, foreign_key: true, null: false

      t.timestamps
    end
  end
end
