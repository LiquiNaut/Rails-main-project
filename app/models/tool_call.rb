class ToolCall < ApplicationRecord
  # Sets up associations to the calling message and the result message.
  acts_as_tool_call # Assumes Message model name

  belongs_to :message
  validates :tool_name, presence: true
end
