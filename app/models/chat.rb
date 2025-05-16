class Chat < ApplicationRecord
  # Includes methods like ask, with_tool, with_instructions, etc.
  # Automatically persists associated messages and tool calls.
  acts_as_chat # Assumes Message and ToolCall model names

  belongs_to :user
  validates :model_id, presence: true
end
