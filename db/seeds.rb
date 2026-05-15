def generate_demo_invoices
  puts "\n Spúšťam generovanie testovacieho datasetu FinanceGPT..."
  puts '=' * 60

  categories = {
    'web development' => ['vývoj webovej aplikácie React + Rails', 'frontend optimalizácia Tailwind', 'REST API integrácia', 'responsive design mobil/tablet'],
    'mobile development' => ['iOS Swift aplikácia', 'Android Kotlin natívna app', 'React Native cross-platform', 'push notifikácie Firebase'],
    'grafický dizajn' => ['logo a firemná identita', 'UI/UX design Figma prototyp', 'print materiály A4/A5', 'ikony SVG set'],
    'IT konzultácie' => ['AWS cloud migrácia', 'bezpečnostný audit systému', 'DevOps CI/CD pipeline', 'softvérová architektúra'],
    'server admin' => ['Linux server správa Ubuntu', 'Docker kontajner deployment', 'PostgreSQL performance tuning', 'automatizované backupy S3'],
    'social media' => ['Facebook Ads kampane', 'Instagram content kalendár', 'LinkedIn B2B lead generation', 'social media reporting'],
    'SEO optimalizácia' => ['on-page SEO technické úpravy', 'Google Analytics 4 setup', 'keyword research SEMrush', 'schema.org markup'],
    'custom software' => ['ERP systém customizácia', 'CRM HubSpot integrácia', 'automatizácia workflow Zapier', 'Electron desktop app'],
    'technická podpora' => ['24/7 SLA support', 'urgent hotfix production', 'bug fixing sprint', 'preventívna údržba'],
    'data analytics' => ['Power BI interaktívne dashboardy', 'SQL business reporty', 'data warehouse Snowflake', 'prediktívna analýza']
  }

  demo_user = User.find_or_create_by(email: 'demo@financegpt.sk') do |u|
    u.password              = 'Demo123!'
    u.password_confirmation = 'Demo123!'
  end
  puts "✓ Demo user: #{demo_user.email} (ID: #{demo_user.id})"

  client_names = [
    'IT Solutions s.r.o.', 'Dizajn Studio SK',
    'Marketing Agency Bratislava', 'Cloud Experts',
    'WebDev Freelancer',         'Mobilní Vývojári',
    'Grafika Pro',               'DevOps Team',
    'SEO Masters',               'Data Analytics Hub',
    'SupportLine',               'Software Custom'
  ]

  puts "✓ Klienti: #{client_names.count} firiem"

  created_count = 0
  current_year  = Date.current.year

  categories.each do |category, phrases|
    10.times do |i|
      client_name = client_names.sample
      phrase = phrases.sample

      # Generovanie dátumov tak, aby sme mali mix po splatnosti a pred splatnosťou
      issue_date = rand(12.months.ago.to_date..1.month.ago.to_date)
      due_date   = issue_date + rand(14..60).days

      total_without_tax = rand(800.0..4500.0).round(2)
      vat_rate          = 20.0
      total_tax         = (total_without_tax * vat_rate / 100).round(2)

      invoice = Invoice.create!(
        user_id: demo_user.id,
        invoice_name: "Faktúra #{category.titleize} ##{i + 1}",
        invoice_number: "FAC-#{1000 + created_count}/#{current_year}",
        issue_date: issue_date,
        due_date: due_date,
        vehicle_information: nil,
        self_issued_invoice: [true, false].sample,
        tax_liability_shift: false,
        product_type: category,
        product_quantity: rand(1..20),
        unit_price_without_tax: rand(50.0..300.0).round(2),
        total_price_without_tax: total_without_tax,
        vat_rate_percentage: vat_rate,
        total_tax_amount_eur: total_tax
      )

      if invoice.persisted?
        Entity.create!(
          entity_name: 'Naša Firma s.r.o.',
          entity_type: 'seller',
          invoice_id: invoice.id
        )
        Entity.create!(
          entity_name: client_name,
          entity_type: 'buyer',
          invoice_id: invoice.id,
          ico: "SK#{rand(10_000_000..99_999_999)}",
          dic: "SK#{rand(1_000_000_000..9_999_999_999)}"
        )
        created_count += 1
        print '.'
      else
        puts "\n  ⚠️  Chyba: #{invoice.errors.full_messages.join(', ')}"
      end
    end
    puts "\n  ✓ #{category}: 10 faktúr"
  end

  puts "\n" + ('=' * 60)
  puts "Vytvorených #{created_count}/100 demo faktúr"

  past_due_count = Invoice.where(user_id: demo_user.id).where('due_date < ?', Date.current).count
  upcoming_count = Invoice.where(user_id: demo_user.id).where('due_date >= ?', Date.current).count

  puts "\n Rozloženie splatnosti:"
  puts "   Po splatnosti (due_date < dnes):  #{past_due_count}"
  puts "   V splatnosti  (due_date >= dnes): #{upcoming_count}"

  puts "\n Finančné súhrny:"
  total       = Invoice.where(user_id: demo_user.id).sum(:total_price_without_tax).round(2)
  overdue_sum = Invoice.where(user_id: demo_user.id).where('due_date < ?', Date.current).sum(:total_price_without_tax).round(2)
  puts "   Celkový obrat:      #{total} EUR"
  puts "   Suma po splatnosti: #{overdue_sum} EUR"

  puts "\n Top 3 klienti (počet faktúr):"
  Entity.where(entity_type: 'buyer', entity_name: client_names)
        .group(:entity_name).count
        .sort_by { |_, v| -v }.first(3)
        .each { |name, cnt| puts "   #{name}: #{cnt} faktúr" }

  puts "\n Ďalší krok: rails runner 'EmbeddingJob.perform_later'"
  puts '=' * 60
end

generate_demo_invoices