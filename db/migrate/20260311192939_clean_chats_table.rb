class CleanChatsTable < ActiveRecord::Migration[8.0]
  def change
    remove_column :chats, :role,    :string
    remove_column :chats, :content, :text
  end
end