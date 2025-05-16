class CreateChats < ActiveRecord::Migration[8.0]
  def change
    create_table :chats do |t|
      t.string :model_id, null: false
      t.references :user, null: false, foreign_key: true
      t.string :role
      t.text :content
      t.jsonb :tool_calls, default: {}, null: false
      t.timestamps
    end
  end
end
