class FixToolCallsTableSchema < ActiveRecord::Migration[8.0]
  def change
    # Rename tool_name to name to match ruby_llm gem expectations
    rename_column :tool_calls, :tool_name, :name
    
    # Add missing thought_signature column
    add_column :tool_calls, :thought_signature, :string
    
    # Drop columns that aren't part of ruby_llm 1.13.2 spec
    # (Keep them if you're using them elsewhere in your app)
    remove_column :tool_calls, :output, :jsonb
    remove_column :tool_calls, :success, :boolean
  end
end
