# frozen_string_literal: true

require 'ruby_llm'
require 'debug'

class SqlGeneratorTool < RubyLLM::Tool
  description <<~DESC.strip
    Si SQL expert tool pre PostgresSQL (verzia 14 alebo novšia). Generuješ len platnú PostgresSQL syntax.
    Generuj IBA SQL dotazy na základe týchto údajov kompatibilné s PostgresSQL.

    SCHÉMA DATABÁZY:
    - invoices (id, user_id, invoice_number, total_price_without_tax, total_tax_amount_eur, issue_date, product_type)
    - entities (id, invoice_id, entity_type, entity_name, first_name, last_name)
    - bank_details (id, invoice_id, iban, swift)

    Si PRÍSNE OBMEDZENÝ na generovanie iba `SELECT` dotazov. Akákoľvek iná operácia (UPDATE, DELETE, INSERT, DROP, ALTER atď.) je ZAKÁZANÁ.
  DESC

  param :sql, desc: 'Platný SQL SELECT dotaz na vykonanie.'

  class Error < StandardError; end

  MAX_RESULT_CHARS = 2000
  EXCLUDED_COLUMNS = %w[embedding].freeze

  def execute(sql:, **arguments)
    Rails.logger.info "Arguments received by SqlGeneratorTool#execute: #{sql.inspect}, #{arguments.inspect}"

    begin
      unless sql.strip.upcase.start_with?('SELECT')
        Rails.logger.warn "Vygenerovaný dotaz nezačína SELECT: #{sql}"
        return 'Chyba zabezpečenia: Bol vygenerovaný nepovolený SQL dotaz. Môžem vykonávať iba SELECT dotazy.'
      end

      safe_sql = sql
      Rails.logger.info "Vykonávam SQL dotaz: #{safe_sql}"
      result = ActiveRecord::Base.connection.execute(safe_sql)

      formatted_result = "Výsledok SQL dotazu:\n"
      if result.present?
        fields = result.fields.reject { |f| EXCLUDED_COLUMNS.include?(f) }
        formatted_result += fields.join(' | ') + "\n"
        formatted_result += ('- ' * (fields.join(' | ').length / 2)) + "\n"
        result.each do |row|
          formatted_result += fields.map { |f| row[f].to_s }.join(' | ') + "\n"
        end
      else
        formatted_result += 'Dotaz nevrátil žiadne výsledky.'
      end

      # if formatted_result.length > MAX_RESULT_CHARS
      #   formatted_result = formatted_result[0..MAX_RESULT_CHARS] + "\n...[výsledok skrátený]"
      # end

      Rails.logger.info "Výsledok SQL dotazu: #{formatted_result}"
      formatted_result
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "Chyba pri vykonávaní SQL dotazu: #{e.message}"
      "Nastala chyba pri vykonávaní SQL dotazu: #{e.message}"
    rescue RubyLLM::Error => e
      Rails.logger.error "Chyba pri volaní LLM v SqlTool: #{e.message}"
      'Nepodarilo sa spojiť s AI pre generovanie SQL dotazu.'
    rescue StandardError => e
      Rails.logger.error "Neočakávaná chyba v SqlTool#execute: #{e.message}"
      'Nastala neočakávaná chyba pri spracovaní SQL požiadavky.'
    end
  end

  # private

  # The `inject_limit` method is commented out to disable automatic LIMIT injection.
  # def inject_limit(sql, max: 50)
  #   return sql if sql.match?( /\bLIMIT\b/i)
  #   "#{sql.rstrip.chomp(';')} LIMIT #{max}"
  # end
end