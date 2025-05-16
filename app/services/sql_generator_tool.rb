# frozen_string_literal: true

require 'ruby_llm'
require 'debug'

class SqlGeneratorTool < RubyLLM::Tool
  description "Si SQL expert tool pre PostgresSQL (verzia 14 alebo novšia). Generuješ len platnú PostgresSQL syntax.
                  Generuj IBA SQL dotazy na základe týchto údajov kompatibilné s PostgresSQL.
                  Si PRÍSNE OBMEDZENÝ na generovanie iba `SELECT` dotazov. Akákoľvek iná operácia (UPDATE, DELETE, INSERT, DROP, ALTER atď.) je ZAKÁZANÁ."

  param :sql_generator, desc: "Platný SQL SELECT dotaz na vykonanie."

  class Error < StandardError; end

  def self.invoice_model_schema
    @invoice_model_schema ||= load_invoice_schema
  end

  def self.load_invoice_schema
    schema_string = ""
    begin
      schema_string += "Tabuľka: invoices\n"
      schema_string += ActiveRecord::Base.connection.columns("invoices").map { |col| "- #{col.name} (#{col.sql_type})" }.join("\n")
      schema_string += "\n\n"

      schema_string += "Tabuľka: entities\n"
      schema_string += ActiveRecord::Base.connection.columns("entities").map { |col| "- #{col.name} (#{col.sql_type})" }.join("\n")
      schema_string += "\n\n"

      schema_string += "Tabuľka: bank_details\n"
      schema_string += ActiveRecord::Base.connection.columns("bank_details").map { |col| "- #{col.name} (#{col.sql_type})" }.join("\n")

    rescue NameError => e
      Rails.logger.error "Chyba pri načítaní schémy: Model nebol nájdený - #{e.message}"
      schema_string += "\nChyba: Nepodarilo sa načítať časť schémy (chýbajúci model?)."
    rescue StandardError => e
      Rails.logger.error "Nepodarilo sa načítať schému databázy: #{e.message}"
      schema_string += "\nChyba pri načítaní schémy databázy."
    end

    schema_string
  end

  def execute(sql_generator:, **arguments)
    Rails.logger.info "Arguments received by SqlGeneratorTool#execute: #{sql_generator.inspect}, #{arguments.inspect}"
    generated_sql_response = sql_generator

    begin
      unless generated_sql_response.strip.upcase.start_with?("SELECT")
        Rails.logger.warn "Vygenerovaný dotaz nezačína SELECT: #{generated_sql_response}"
        return "Chyba zabezpečenia: Bol vygenerovaný nepovolený SQL dotaz. Môžem vykonávať iba SELECT dotazy."
      end

      Rails.logger.info "Vykonávam SQL dotaz: #{generated_sql_response}"
      result = ActiveRecord::Base.connection.execute(generated_sql_response)

      # Formátovanie výsledku (toto je len jednoduchý príklad, komplexnejšie výsledky si vyžadujú sofistikovanejšie spracovanie)
      formatted_result = "Výsledok SQL dotazu:\n"
      if result.present?
        # Pridaj názvy stĺpcov
        formatted_result += result.fields.join(" | ") + "\n"
        formatted_result += "- " * (result.fields.join(" | ").length / 2) + "\n"
        # Pridaj riadky dát
        result.each do |row|
          formatted_result += row.values.map(&:to_s).join(" | ") + "\n"
        end
      else
        formatted_result += "Dotaz nevrátil žiadne výsledky."
      end


      Rails.logger.info "Výsledok SQL dotazu: #{formatted_result}"

      return formatted_result

    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "Chyba pri vykonávaní SQL dotazu: #{e.message}"
      return "Nastala chyba pri vykonávaní SQL dotazu: #{e.message}"
    rescue RubyLLM::Error => e
      Rails.logger.error "Chyba pri volaní LLM v SqlTool (generovanie dotazu): #{e.message}"
      return "Nepodarilo sa spojiť s AI pre generovanie SQL dotazu."
    rescue => e
      Rails.logger.error "Neočakávaná chyba v SqlTool#execute: #{e.message}"
      return "Nastala neočakávaná chyba pri spracovaní SQL požiadavky."
    end
  end
end