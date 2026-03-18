class AddEmbeddingToInvoices < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    enable_extension 'vector' unless extension_enabled?('vector')

    add_column :invoices, :embedding, :vector, limit: 1536, null: true

    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_invoices_on_embedding
      ON invoices USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end
end
