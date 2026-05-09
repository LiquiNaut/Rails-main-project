class SemanticSearchTool < RubyLLM::Tool
  description 'Sémantické vyhľadávanie faktúr podľa obsahu a kontextu. ' \
              'Použi keď používateľ hľadá faktúry podľa popisu alebo témy, ' \
              "napr. 'faktúry kde som predával softvér', 'projekty súvisiace s webom', " \
              "'práce pre IT klientov'. " \
              'NEPOUŽÍVAJ na čísla, dátumy, súčty alebo presné hodnoty — na to použi sql_generator.'

  param :query, desc: 'Prirodzený jazyk — čo hľadáš vo faktúrach.'
  param :limit, desc: 'Maximálny počet výsledkov (default 5).', required: false

  def initialize(user)
    super()
    @user_id = user.id
  end

  def execute(query:, limit: 5, **)
    Rails.logger.info "SemanticSearchTool: '#{query}', limit=#{limit}"

    vector = EmbeddingService.embed(query)
    return 'Chyba: nepodarilo sa vytvoriť embedding pre dotaz.' unless vector

    results = Invoice
              .where(user_id: @user_id)
              .nearest_neighbors(:embedding, vector, distance: :cosine)
              .limit(limit.to_i.clamp(1, 20))
              .includes(:entities) # upravené na :entities namiesto :entity

    return "Nenašli sa žiadne faktúry pre dotaz: '#{query}'." if results.empty?

    formatted = results.map.with_index(1) do |inv, i|
      score = inv.neighbor_distance ? (1 - inv.neighbor_distance).round(3) : 'N/A'
      "#{i}. Faktúra ##{inv.invoice_number} | " \
        "Kupujúci: #{inv.buyer&.entity_name} | " \
        "Produkt: #{inv.product_type} | " \
        "Podobnosť: #{score}"
    end

    "Sémantické výsledky pre '#{query}':\n" + formatted.join("\n")
  rescue StandardError => e
    Rails.logger.error "SemanticSearchTool chyba: #{e.message}"
    "Nastala chyba pri sémantickom vyhľadávaní: #{e.message}"
  end
end
