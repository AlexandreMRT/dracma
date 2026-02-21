# frozen_string_literal: true
# typed: true

# Pure-Ruby VADER-inspired news sentiment analyzer.
# Replaces Python's nltk.sentiment.vader with a minimal keyword-based approach.
module SentimentAnalyzer
  extend T::Sig

  # Portuguese financial keywords with sentiment weights
  PT_POSITIVE = {
    "alta" => 2.0, "subiu" => 2.0, "sobe" => 1.5, "valoriza" => 2.0, "valorização" => 2.0,
    "lucro" => 2.5, "lucros" => 2.5, "crescimento" => 1.5, "cresce" => 1.5, "cresceu" => 1.5,
    "recorde" => 2.0, "positivo" => 1.5, "otimista" => 1.5, "supera" => 1.5, "superou" => 1.5,
    "dividendos" => 1.5, "rentabilidade" => 1.5, "aprovação" => 1.5, "aprovado" => 1.5,
    "expansão" => 1.5, "expande" => 1.5, "contrato" => 1.0, "parceria" => 1.0,
    "aquisição" => 1.0, "investimento" => 1.0, "recomendação" => 0.5, "compra" => 1.0
  }.freeze

  PT_NEGATIVE = {
    "queda" => -2.0, "caiu" => -2.0, "cai" => -1.5, "desvaloriza" => -2.0, "desvalorização" => -2.0,
    "prejuízo" => -2.5, "prejuízos" => -2.5, "perdas" => -2.0, "perda" => -2.0,
    "negativo" => -1.5, "pessimista" => -1.5, "rebaixado" => -2.0, "rebaixa" => -2.0,
    "dívida" => -1.5, "dívidas" => -1.5, "endividamento" => -1.5, "risco" => -1.0,
    "crise" => -2.0, "problema" => -1.5, "problemas" => -1.5, "investigação" => -1.5,
    "multa" => -2.0, "fraude" => -3.0, "demissão" => -1.5, "demissões" => -1.5,
    "rombo" => -2.5, "escândalo" => -3.0, "falência" => -3.0
  }.freeze

  # English financial keywords
  EN_POSITIVE = {
    "surge" => 2.5, "soar" => 2.0, "rally" => 2.0, "gain" => 1.5, "rise" => 1.5,
    "profit" => 2.0, "growth" => 1.5, "record" => 2.0, "beat" => 1.5, "exceeds" => 1.5,
    "bullish" => 2.0, "upgrade" => 2.0, "buy" => 1.0, "outperform" => 1.5,
    "dividend" => 1.5, "expansion" => 1.5, "acquisition" => 1.0, "partnership" => 1.0
  }.freeze

  EN_NEGATIVE = {
    "crash" => -3.0, "plunge" => -2.5, "drop" => -2.0, "fall" => -2.0, "decline" => -1.5,
    "loss" => -2.0, "deficit" => -2.0, "downgrade" => -2.0, "sell" => -1.0, "underperform" => -1.5,
    "bearish" => -2.0, "recession" => -2.5, "crisis" => -2.0, "fraud" => -3.0,
    "bankruptcy" => -3.0, "layoff" => -1.5, "investigation" => -1.5, "fine" => -2.0,
    "risk" => -1.0, "debt" => -1.5, "scandal" => -3.0
  }.freeze

  ALL_KEYWORDS = {}.merge(PT_POSITIVE).merge(PT_NEGATIVE).merge(EN_POSITIVE).merge(EN_NEGATIVE).freeze

  # Analyze a single text and return a compound score (-1.0 to +1.0).
  sig { params(text: T.nilable(String)).returns(Float) }
  def self.score(text)
    return 0.0 if text.nil? || text.empty?

    words = text.downcase.split(/[\s.,;:!?()]+/)
    total = 0.0
    count = 0

    words.each do |w|
      if (weight = ALL_KEYWORDS[w])
        total += weight
        count += 1
      end
    end

    return 0.0 if count.zero?

    # Normalize to -1..+1 range using a tanh-like approach
    raw = total / [ count, 1 ].max
    raw / (1.0 + raw.abs) # Soft normalization
  end

  # Analyze multiple texts and return average score + best headline.
  sig { params(texts: T.nilable(T::Array[T.untyped]), lang: Symbol).returns([ T.nilable(Float), T.nilable(String) ]) }
  def self.analyze(texts, lang: :en)
    return [ nil, nil ] if texts.nil? || texts.empty?

    scores = texts.filter_map do |item|
      text = item.is_a?(Hash) ? (item[:text] || item["text"]) : item.to_s
      next if text.nil? || text.empty?

      score(text)
    end

    return [ nil, nil ] if scores.empty?

    avg = T.cast(scores.sum / scores.size.to_f, Float)

    first_item = T.must(texts.first)
    headline =
      if first_item.is_a?(Hash)
        raw_headline = first_item[:title] || first_item["title"]
        raw_headline&.to_s
      else
        first_item.to_s
      end

    [ avg, headline ]
  end

  # Determine sentiment label from combined score.
  sig { params(combined_score: T.nilable(Float)).returns(T.nilable(String)) }
  def self.label(combined_score)
    return nil if combined_score.nil?

    if combined_score >= 0.2
      "positive"
    elsif combined_score <= -0.2
      "negative"
    else
      "neutral"
    end
  end
end
