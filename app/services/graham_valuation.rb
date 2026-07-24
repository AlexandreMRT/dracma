# frozen_string_literal: true

# Benjamin Graham valuation multiples: Graham Number, Graham Multiple, and
# Margin of Safety. Classic value-investing formulas used to flag potentially
# undervalued stocks. All inputs are the ticker's native-currency values
# (EPS, P/E, P/B, price) — the resulting multiples are unit-agnostic ratios.
module GrahamValuation
  # Graham's classic rule of thumb: P/E x P/B should not exceed 22.5.
  MULTIPLE_THRESHOLD = 22.5

  def self.calculate(eps:, pb_ratio:, pe_ratio:, price:)
    bvps = book_value_per_share(price, pb_ratio)
    number = graham_number(eps, bvps)

    {
      graham_number: number&.round(2),
      graham_multiple: graham_multiple(pe_ratio, pb_ratio),
      margin_of_safety_percent: margin_of_safety_percent(number, price)
    }
  end

  def self.book_value_per_share(price, pb_ratio)
    return nil if price.to_f <= 0.0 || pb_ratio.to_f <= 0.0

    price.to_f / pb_ratio.to_f
  end

  def self.graham_number(eps, bvps)
    return nil if eps.to_f <= 0.0 || bvps.to_f <= 0.0

    Math.sqrt(MULTIPLE_THRESHOLD * eps.to_f * bvps.to_f)
  end

  def self.graham_multiple(pe_ratio, pb_ratio)
    return nil if pe_ratio.to_f <= 0.0 || pb_ratio.to_f <= 0.0

    (pe_ratio.to_f * pb_ratio.to_f).round(2)
  end

  def self.margin_of_safety_percent(graham_number, price)
    return nil if graham_number.to_f <= 0.0 || price.to_f <= 0.0

    (((graham_number - price.to_f) / graham_number) * 100).round(2)
  end

  private_class_method :book_value_per_share, :graham_number, :graham_multiple, :margin_of_safety_percent
end
