# frozen_string_literal: true

require 'test_helper'

class SqlGeneratorToolTest < ActiveSupport::TestCase
  setup do
    @user = Struct.new(:id).new(1)
    @tool = SqlGeneratorTool.new(@user)
  end

  test 'rejects DELETE statements' do
    result = @tool.execute(sql: 'DELETE FROM invoices')
    assert_match(/SELECT/i, result)
  end

  test 'rejects UPDATE statements' do
    result = @tool.execute(sql: "UPDATE invoices SET status='paid' WHERE 1=1")
    assert_match(/SELECT/i, result)
  end

  test 'rejects DROP TABLE' do
    result = @tool.execute(sql: 'DROP TABLE invoices')
    assert_match(/SELECT/i, result)
  end

  test 'rejects INSERT statements' do
    result = @tool.execute(sql: 'INSERT INTO invoices (id) VALUES (1)')
    assert_match(/SELECT/i, result)
  end

  test 'allows valid SELECT query' do
    result = @tool.execute(sql: 'SELECT COUNT(*) FROM invoices')
    assert_no_match(/Chyba/i, result.to_s)
  end
end
