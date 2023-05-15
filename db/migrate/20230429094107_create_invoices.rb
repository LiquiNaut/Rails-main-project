class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_name #nazov faktury

      t.string :invoice_number # poradové číslo faktúry
      t.date :issue_date # dátum vystavenia faktúry
      t.date :shipping_date # dodací alebo prepravný dátum
      t.date :due_date # datum splatnosti
      t.string :vehicle_information # údaje o dodanom novom dopravnom prostriedku
      t.boolean :self_issued_invoice # vyhotovenie faktúry odberateľom
      t.boolean :tax_liability_shift # prenesenie daňovej povinnosti
      t.string :tax_adjustment_type # úprava zdaňovania prirážky

      t.string :product_type # druh dodaného tovaru
      t.integer :product_quantity # množstvo dodaného tovaru
      t.decimal :unit_price_without_tax, precision: 10, scale: 2 # jednotková cena bez DPH
      t.decimal :total_price_without_tax, precision: 10, scale: 2 # celková cena bez DPH
      t.decimal :vat_rate_percentage, precision: 4, scale: 2 # sadzba DPH (percentuálna hodnota)
      t.decimal :total_tax_amount_eur, precision: 10, scale: 2 # výška dane spolu v eurách

      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
