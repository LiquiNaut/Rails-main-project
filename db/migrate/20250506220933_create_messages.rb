class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.string :model_id
      t.integer :input_tokens
      t.integer :output_tokens
      t.references :tool_call, foreign_key: true
      t.timestamps
    end
  end
end
