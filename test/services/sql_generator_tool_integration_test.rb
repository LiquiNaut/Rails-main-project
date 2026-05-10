# frozen_string_literal: true

require 'test_helper'

class SqlGeneratorToolIntegrationTest < ActiveSupport::TestCase
  setup do
    @user_a = User.create!(
      email: 'user_a@integration.test',
      password: 'Test123!',
      password_confirmation: 'Test123!'
    )
    @user_b = User.create!(
      email: 'user_b@integration.test',
      password: 'Test123!',
      password_confirmation: 'Test123!'
    )

    3.times do |i|
      Invoice.create!(user: @user_a, invoice_number: "INTTEST-#{i + 1}")
    end

    @tool_a = SqlGeneratorTool.new(@user_a)
    @tool_b = SqlGeneratorTool.new(@user_b)
  end

  test 'user_a sees only their own invoices' do
    result = @tool_a.execute(sql: 'SELECT COUNT(*) FROM invoices')
    assert_match(/\b3\b/, result)
  end

  test 'user_b with no invoices sees 0 results' do
    result = @tool_b.execute(sql: 'SELECT COUNT(*) FROM invoices')
    assert_match(/\b0\b/, result)
  end

  test 'user_b cannot bypass tenant filter with explicit user_id condition' do
    result = @tool_b.execute(sql: "SELECT COUNT(*) FROM invoices WHERE user_id = #{@user_a.id}")
    assert_match(/\b0\b/, result)
  end

  test 'valid SELECT returns invoice data without error' do
    result = @tool_a.execute(sql: 'SELECT invoice_number FROM invoices')
    assert_no_match(/Chyba/i, result)
    assert_match(/INTTEST-/, result)
  end
end
