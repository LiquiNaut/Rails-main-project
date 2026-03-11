# db/seeds.rb

# Vyčistenie existujúcich dát
puts "Čistenie databázy..."
BankDetail.destroy_all
Entity.destroy_all
Invoice.destroy_all
User.where(email: 'testuzivatel@example.sk').destroy_all

# Vytvorenie používateľa
puts "Vytvorenie používateľa..."
user = User.create!(
  email: 'testuzivatel@example.sk',
  password: 'password123',
  password_confirmation: 'password123'
)

# Dáta faktúr
invoices_data = [
  { invoice_name: 'Faktúra 1',  invoice_number: '2025001', issue_date: '2025-01-01', shipping_date: '2025-01-02', due_date: '2025-01-15', product_type: 'Potraviny',           product_quantity: 10, unit_price_without_tax: 5.00,    total_price_without_tax: 50.00,   vat_rate_percentage: 20.00, total_tax_amount_eur: 10.00,  vehicle_information: 'Dodávka KE123AB',  self_issued_invoice: false, tax_liability_shift: false, tax_adjustment_type: 'Nevzťahuje sa' },
  { invoice_name: 'Faktúra 2',  invoice_number: '2025002', issue_date: '2025-01-05', shipping_date: '2025-01-06', due_date: '2025-01-20', product_type: 'Elektronika',         product_quantity: 2,  unit_price_without_tax: 300.00,  total_price_without_tax: 600.00,  vat_rate_percentage: 20.00, total_tax_amount_eur: 120.00, vehicle_information: 'Kamión BA456CD',   self_issued_invoice: true,  tax_liability_shift: true,  tax_adjustment_type: 'Zvýšenie'      },
  { invoice_name: 'Faktúra 3',  invoice_number: '2025003', issue_date: '2024-12-15', shipping_date: '2024-12-16', due_date: '2024-12-30', product_type: 'Nábytok',             product_quantity: 4,  unit_price_without_tax: 200.00,  total_price_without_tax: 800.00,  vat_rate_percentage: 20.00, total_tax_amount_eur: 160.00, vehicle_information: nil,                self_issued_invoice: false, tax_liability_shift: false, tax_adjustment_type: 'Nevzťahuje sa' },
  { invoice_name: 'Faktúra 4',  invoice_number: '2025004', issue_date: '2025-01-10', shipping_date: '2025-01-11', due_date: '2025-01-25', product_type: 'Kozmetika',           product_quantity: 20, unit_price_without_tax: 2.50,    total_price_without_tax: 50.00,   vat_rate_percentage: 20.00, total_tax_amount_eur: 10.00,  vehicle_information: 'Dodávka TN789EF', self_issued_invoice: true,  tax_liability_shift: true,  tax_adjustment_type: 'Zvýšenie'      },
  { invoice_name: 'Faktúra 5',  invoice_number: '2024010', issue_date: '2024-11-01', shipping_date: '2024-11-02', due_date: '2024-11-15', product_type: 'Oblečenie',           product_quantity: 5,  unit_price_without_tax: 100.00,  total_price_without_tax: 500.00,  vat_rate_percentage: 20.00, total_tax_amount_eur: 100.00, vehicle_information: nil,                self_issued_invoice: false, tax_liability_shift: false, tax_adjustment_type: 'Nevzťahuje sa' },
  { invoice_name: 'Faktúra 6',  invoice_number: '2023007', issue_date: '2023-06-15', shipping_date: '2023-06-16', due_date: '2023-07-01', product_type: 'Potraviny',           product_quantity: 8,  unit_price_without_tax: 8.00,    total_price_without_tax: 64.00,   vat_rate_percentage: 20.00, total_tax_amount_eur: 12.80,  vehicle_information: 'Kamión NR321GH',  self_issued_invoice: true,  tax_liability_shift: true,  tax_adjustment_type: 'Zníženie'      },
  { invoice_name: 'Faktúra 7',  invoice_number: '2023008', issue_date: '2023-08-10', shipping_date: '2023-08-11', due_date: '2023-08-25', product_type: 'Elektronika',         product_quantity: 1,  unit_price_without_tax: 1000.00, total_price_without_tax: 1000.00, vat_rate_percentage: 20.00, total_tax_amount_eur: 200.00, vehicle_information: nil,                self_issued_invoice: false, tax_liability_shift: false, tax_adjustment_type: 'Nevzťahuje sa' },
  { invoice_name: 'Faktúra 8',  invoice_number: '2023009', issue_date: '2023-12-20', shipping_date: '2023-12-21', due_date: '2024-01-05', product_type: 'Kancelárske potreby', product_quantity: 10, unit_price_without_tax: 12.00,   total_price_without_tax: 120.00,  vat_rate_percentage: 20.00, total_tax_amount_eur: 24.00,  vehicle_information: 'Dodávka BB654IJ', self_issued_invoice: true,  tax_liability_shift: true,  tax_adjustment_type: 'Zníženie'      },
  { invoice_name: 'Faktúra 9',  invoice_number: '2025005', issue_date: '2025-01-10', shipping_date: '2025-01-11', due_date: '2025-01-25', product_type: 'Oblečenie',           product_quantity: 3,  unit_price_without_tax: 150.00,  total_price_without_tax: 450.00,  vat_rate_percentage: 20.00, total_tax_amount_eur: 90.00,  vehicle_information: 'Kamión ZA987KL',  self_issued_invoice: true,  tax_liability_shift: true,  tax_adjustment_type: 'Zvýšenie'      },
  { invoice_name: 'Faktúra 10', invoice_number: '2025006', issue_date: '2025-01-15', shipping_date: '2025-01-16', due_date: '2025-01-30', product_type: 'Nábytok',             product_quantity: 1,  unit_price_without_tax: 800.00,  total_price_without_tax: 800.00,  vat_rate_percentage: 20.00, total_tax_amount_eur: 160.00, vehicle_information: nil,                self_issued_invoice: false, tax_liability_shift: false, tax_adjustment_type: 'Nevzťahuje sa' },
]

# Dáta entít (klientov)
entities_data = [
  { entity_name: 'Klient Alfa',    entity_type: 'buyer',  first_name: 'Jozef',    last_name: 'Novák',   street: 'Hlavná 1',  street_note: 'Blok A', city: 'Bratislava',       postal_code: '81101', country: 'Slovensko', ico: '12345678', dic: '1234567890', ic_dph: 'SK1234567890' },
  { entity_name: 'Klient Beta',    entity_type: 'buyer',  first_name: 'Peter',    last_name: 'Kováč',   street: 'Hlavná 2',  street_note: 'Blok B', city: 'Košice',           postal_code: '04001', country: 'Slovensko', ico: '87654321', dic: '9876543210', ic_dph: 'SK9876543210' },
  { entity_name: 'Klient Gama',    entity_type: 'buyer',  first_name: 'Anna',     last_name: 'Tóthová', street: 'Hlavná 3',  street_note: 'Blok C', city: 'Žilina',           postal_code: '01001', country: 'Slovensko', ico: '12340000', dic: '1234000000', ic_dph: 'SK1234000000' },
  { entity_name: 'Klient Delta',   entity_type: 'buyer',  first_name: 'Martin',   last_name: 'Horváth', street: 'Hlavná 4',  street_note: 'Blok D', city: 'Prešov',           postal_code: '08001', country: 'Slovensko', ico: '87650000', dic: '8765000000', ic_dph: 'SK8765000000' },
  { entity_name: 'Klient Epsilon', entity_type: 'buyer',  first_name: 'Mária',    last_name: 'Černá',   street: 'Hlavná 5',  street_note: 'Blok E', city: 'Nitra',            postal_code: '94901', country: 'Slovensko', ico: '12345000', dic: '1234500000', ic_dph: 'SK1234500000' },
  { entity_name: 'Klient Zeta',    entity_type: 'buyer',  first_name: 'Ivan',     last_name: 'Šimko',   street: 'Hlavná 6',  street_note: 'Blok F', city: 'Trnava',           postal_code: '91701', country: 'Slovensko', ico: '87654000', dic: '8765400000', ic_dph: 'SK8765400000' },
  { entity_name: 'Klient Eta',     entity_type: 'buyer',  first_name: 'Katarína', last_name: 'Novotná', street: 'Hlavná 7',  street_note: 'Blok G', city: 'Trenčín',          postal_code: '91101', country: 'Slovensko', ico: '12345600', dic: '1234567000', ic_dph: 'SK1234567000' },
  { entity_name: 'Klient Teta',    entity_type: 'buyer',  first_name: 'Ľuboš',    last_name: 'Kráľ',   street: 'Hlavná 8',  street_note: 'Blok H', city: 'Banská Bystrica',  postal_code: '97401', country: 'Slovensko', ico: '87654300', dic: '8765432100', ic_dph: 'SK8765432100' },
  { entity_name: 'Klient Omega',   entity_type: 'buyer',  first_name: 'Jana',     last_name: 'Mihálik', street: 'Hlavná 9',  street_note: 'Blok I', city: 'Poprad',           postal_code: '05801', country: 'Slovensko', ico: '12340070', dic: '1234007000', ic_dph: 'SK1234007000' },
  { entity_name: 'Klient Sigma',   entity_type: 'buyer',  first_name: 'Juraj',    last_name: 'Bielik',  street: 'Hlavná 10', street_note: 'Blok J', city: 'Lučenec',          postal_code: '98401', country: 'Slovensko', ico: '87650070', dic: '8765007000', ic_dph: 'SK8765007000' },
]

# Dáta bankových detailov
bank_details_data = [
  { bank_name: 'Slovenská sporiteľňa', iban: 'SK12 3456 7890 1234 5678 901', swift: 'GIBASKBX',  var_symbol: '2025001', konst_symbol: '0308' },
  { bank_name: 'Tatra banka',          iban: 'SK34 5678 9012 3456 7890 012', swift: 'TATRASKBX', var_symbol: '2025002', konst_symbol: '0308' },
  { bank_name: 'ČSOB banka',           iban: 'SK56 7890 1234 5678 9012 345', swift: 'CEKOSKBX',  var_symbol: '2025003', konst_symbol: '0308' },
  { bank_name: 'Slovenská sporiteľňa', iban: 'SK78 1234 5678 9012 3456 789', swift: 'GIBASKBX',  var_symbol: '2025004', konst_symbol: '0308' },
  { bank_name: 'Tatra banka',          iban: 'SK90 3456 7890 1234 5678 901', swift: 'TATRASKBX', var_symbol: '2024010', konst_symbol: '0308' },
  { bank_name: 'ČSOB banka',           iban: 'SK12 5678 9012 3456 7890 123', swift: 'CEKOSKBX',  var_symbol: '2023007', konst_symbol: '0308' },
  { bank_name: 'Slovenská sporiteľňa', iban: 'SK34 7890 1234 5678 9012 345', swift: 'GIBASKBX',  var_symbol: '2023008', konst_symbol: '0308' },
  { bank_name: 'Tatra banka',          iban: 'SK56 9012 3456 7890 1234 567', swift: 'TATRASKBX', var_symbol: '2023009', konst_symbol: '0308' },
  { bank_name: 'ČSOB banka',           iban: 'SK78 1234 5678 9012 3456 789', swift: 'CEKOSKBX',  var_symbol: '2025005', konst_symbol: '0308' },
  { bank_name: 'Slovenská sporiteľňa', iban: 'SK90 3456 7890 1234 5678 901', swift: 'GIBASKBX',  var_symbol: '2025006', konst_symbol: '0308' },
]

# Vytvorenie faktúr so závislosťami
puts "Vytvorenie faktúr, entít a bankových detailov..."
invoices_data.each_with_index do |inv_data, i|
  invoice = Invoice.create!(inv_data.merge(user: user))

  # Crear seller (prvá entita)
  seller_data = entities_data[i].merge(invoice: invoice, entity_type: 'seller')
  Entity.create!(seller_data)
  
  # Vytvoriť buyer (ďalšia entita)
  buyer_data = entities_data[(i + 1) % entities_data.size].merge(invoice: invoice, entity_type: 'buyer')
  Entity.create!(buyer_data)
  
  BankDetail.create!(bank_details_data[i].merge(invoice: invoice))

  puts "  ✓ #{invoice.invoice_name} (#{invoice.invoice_number})"
end

puts "\nHotovo! Importovaných #{Invoice.count} faktúr."
