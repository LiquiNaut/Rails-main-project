class ToolCall < ApplicationRecord
  # Sets up associations to the calling message and the result message.
  acts_as_tool_call

  belongs_to :message
  validates :name, presence: true
end
