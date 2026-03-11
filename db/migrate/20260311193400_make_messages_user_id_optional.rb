class MakeMessagesUserIdOptional < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :messages, :users
    change_column_null :messages, :user_id, true
  end
end