namespace :embeddings do
  desc 'Vektorizuj všetky faktúry bez embeddingu'
  task backfill: :environment do
    scope = Invoice.all
    total = scope.count
    puts "Spracovávam #{total} faktúr..."

    scope.find_each.with_index(1) do |invoice, i|
      EmbeddingJob.perform_now(invoice.id)
      print '.' if (i % 10).zero?
    end

    puts "\nHotovo! #{total} jobov zaradených do fronty."
  end
end
