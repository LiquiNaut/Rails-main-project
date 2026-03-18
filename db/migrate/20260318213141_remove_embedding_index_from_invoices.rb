class RemoveEmbeddingIndexFromInvoices < ActiveRecord::Migration[8.0]
  def change
    execute "DROP INDEX IF EXISTS index_invoices_on_embedding;"
  end
end