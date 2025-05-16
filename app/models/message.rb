class Message < ApplicationRecord
  # Provides methods like tool_call?, tool_result?
  acts_as_message # Assumes Chat and ToolCall model names

  belongs_to :chat
  belongs_to :user
  belongs_to :tool_call, optional: true

  validates :role, presence: true
  validates :chat, presence: true
end
