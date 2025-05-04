require 'matrix'
require 'ruby_llm'

# Centroidy sa vypočítajú raz pri štarte aplikácie.
module IntentClassifier

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
    return 0.0 if norm_product.zero? # Vyhneme sa deleniu nulou

    vector_1.inner_product(vector_2) / norm_product
  rescue ArgumentError => e
      Rails.logger.error "Chyba pri výpočte kosínusovej podobnosti: #{e.message}"
      0.0 # Vrátime 0.0 v prípade chyby (napr. nezhodné dimenzie)
  end

  # 3) Generovanie centroidných embeddings pre každú triedu
  # Toto sa spustí len raz pri inicializácii aplikácie.
  Rails.logger.info "IntentClassifier: Začínam výpočet centroidov..."
  CENTROIDS = CLASS_EXAMPLES.transform_values do |examples|
    begin
      vectors = examples.map do |text|
        embedding_result = RubyLLM.embed(text)
        embedding_result.vectors
      end

      # Odstránenie prípadných nil hodnôt (ak embedding zlyhal)
      vectors.compact!
      next nil if vectors.empty? # Ak žiadny embedding nebol úspešný

      dim = vectors.first.size
      centroid = Array.new(dim, 0.0)
      vectors.each { |v| v.each_with_index { |x, i| centroid[i] += x } }
      centroid.map! { |sum| sum / vectors.size.to_f }
      centroid
    rescue RubyLLM::Error => e
      Rails.logger.error "IntentClassifier: Nepodarilo sa získať embedding pre príklad: #{e.message}"
      nil
    rescue => e
       Rails.logger.error "IntentClassifier: Neočakávaná chyba pri spracovaní príkladov: #{e.message}"
       nil
    end
  end.compact # Odstránime triedy, pre ktoré sa nepodarilo vypočítať centroid

  if CENTROIDS.empty?
      Rails.logger.warn "IntentClassifier: Nepodarilo sa vypočítať žiadne centroidy!"
  else
      Rails.logger.info "IntentClassifier: Centroidy úspešne vypočítané pre zámery: #{CENTROIDS.keys.join(', ')}"
  end

  def self.classify(text)
    # Skontrolujeme, či máme nejaké centroidy na porovnanie
    return :general_chat if CENTROIDS.empty? # Ak nemáme centroidy, vrátime predvolený zámer
    return :general_chat if text.nil? || text.strip.empty? # Prázdny vstup považujeme za všeobecný chat

    begin
      input_vec = RubyLLM.embed(text).vectors
      return :general_chat if input_vec.nil? || input_vec.empty? # Ak embedding zlyhá

      # Vypočítame podobnosť ku každému centroidu
      scores = CENTROIDS.transform_values do |centroid|
        cosine_similarity(input_vec, centroid)
      end

      # Vyberieme triedu s najvyššou podobnosťou
      best_match = scores.max_by { |_cls, sim| sim }
      best_match ? best_match[0] : :general_chat

    rescue RubyLLM::Error => e
      Rails.logger.error "IntentClassifier: Chyba pri získavaní embeddingu pre vstupný text: #{e.message}"
      :general_chat
    rescue => e
      Rails.logger.error "IntentClassifier: Chyba pri klasifikácii textu: #{e.message}"
      :general_chat
    end
  end
end