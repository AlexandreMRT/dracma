# frozen_string_literal: true

require "test_helper"

class GrahamValuationTest < ActiveSupport::TestCase
  test "calculates graham number, multiple, and margin of safety for typical value stock" do
    result = GrahamValuation.calculate(eps: 3.2, pb_ratio: 1.8, pe_ratio: 10.5, price: 38.5)

    assert_in_delta 39.24, result[:graham_number], 0.01
    assert_in_delta 18.9, result[:graham_multiple], 0.01
    assert_in_delta 1.89, result[:margin_of_safety_percent], 0.01
  end

  test "returns nil graham_number when eps is zero or negative" do
    result = GrahamValuation.calculate(eps: 0.0, pb_ratio: 1.8, pe_ratio: 10.5, price: 38.5)

    assert_nil result[:graham_number]
    assert_nil result[:margin_of_safety_percent]
  end

  test "returns nil graham_number when pb_ratio is missing" do
    result = GrahamValuation.calculate(eps: 3.2, pb_ratio: nil, pe_ratio: 10.5, price: 38.5)

    assert_nil result[:graham_number]
    assert_nil result[:margin_of_safety_percent]
  end

  test "returns nil graham_multiple when pe_ratio or pb_ratio is missing" do
    result = GrahamValuation.calculate(eps: 3.2, pb_ratio: 1.8, pe_ratio: nil, price: 38.5)

    assert_nil result[:graham_multiple]
  end

  test "margin of safety is negative when price exceeds graham number" do
    result = GrahamValuation.calculate(eps: 1.0, pb_ratio: 1.0, pe_ratio: 30.0, price: 100.0)

    assert_operator result[:margin_of_safety_percent], :<, 0
  end

  test "handles nil price gracefully" do
    result = GrahamValuation.calculate(eps: 3.2, pb_ratio: 1.8, pe_ratio: 10.5, price: nil)

    assert_nil result[:graham_number]
    assert_nil result[:margin_of_safety_percent]
  end
end
