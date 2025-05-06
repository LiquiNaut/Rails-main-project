require 'matrix'
require 'ruby_llm'

module XIntentClassifier

  CLASS_EXAMPLES = {
    sql_query: [
      "Zobraz všetky nezaplatené faktúry zo septembra 2024.",
      "Ukáž mi faktúry s platobným stavom unpaid za mesiac september 2024."
    ],
    knowledge_request: [
      "Ako vyplniť položku DPH na faktúre?",
      "Kde nájdem aktuálne smernice k fakturácii?"
    ],
    general_chat: [
      "Ahoj, ako sa máš?",
      "Čo je nové?"
    ]
  }.freeze

  def self.cosine_similarity(vec_a, vec_b)
    return 0.0 if vec_a.nil? || vec_b.nil? || vec_a.empty? || vec_b.empty? # Základná kontrola

    vector_1 = Vector.elements(vec_a)
    vector_2 = Vector.elements(vec_b)
    norm_product = vector_1.norm * vector_2.norm
    return 0.0 if norm_product.zero?

    vector_1.inner_product(vector_2) / norm_product
  rescue ArgumentError => e
      Rails.logger.error "Chyba pri výpočte kosínusovej podobnosti: #{e.message}"
      0.0
  end

  Rails.logger.info "XIntentClassifier: Začínam výpočet centroidov..."
  CENTROIDS = CLASS_EXAMPLES.transform_values do |examples|
    begin
      vectors = examples.map do |text|
        embedding_result = RubyLLM.embed(text)
        embedding_result.vectors
      end

      # Odstránenie prípadných nil hodnôt (ak embedding zlyhal)
      vectors.compact!
      next nil if vectors.empty?

      dim = vectors.first.size
      centroid = Array.new(dim, 0.0)
      vectors.each { |v| v.each_with_index { |x, i| centroid[i] += x } }
      centroid.map! { |sum| sum / vectors.size.to_f }
      centroid
    rescue RubyLLM::Error => e
      Rails.logger.error "XIntentClassifier: Nepodarilo sa získať embedding pre príklad: #{e.message}"
      nil
    rescue => e
       Rails.logger.error "XIntentClassifier: Neočakávaná chyba pri spracovaní príkladov: #{e.message}"
       nil
    end
  end.compact

  if CENTROIDS.empty?
      Rails.logger.warn "XIntentClassifier: Nepodarilo sa vypočítať žiadne centroidy!"
  else
      Rails.logger.info "XIntentClassifier: Centroidy úspešne vypočítané pre zámery: #{CENTROIDS.keys.join(', ')}"
  end

  def self.classify(text)
    return :general_chat if CENTROIDS.empty?
    return :general_chat if text.nil? || text.strip.empty?

    begin
      input_vec = RubyLLM.embed(text).vectors
      return :general_chat if input_vec.nil? || input_vec.empty?

      scores = CENTROIDS.transform_values do |centroid|
        cosine_similarity(input_vec, centroid)
      end

      best_match = scores.max_by { |_cls, sim| sim }
      best_match ? best_match[0] : :general_chat

    rescue RubyLLM::Error => e
      Rails.logger.error "XIntentClassifier: Chyba pri získavaní embeddingu pre vstupný text: #{e.message}"
      :general_chat
    rescue => e
      Rails.logger.error "XIntentClassifier: Chyba pri klasifikácii textu: #{e.message}"
      :general_chat
    end
  end
end