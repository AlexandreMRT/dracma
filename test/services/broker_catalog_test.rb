# frozen_string_literal: true

require "test_helper"

class BrokerCatalogTest < ActiveSupport::TestCase
  test "all returns frozen hash" do
    assert_kind_of Hash, BrokerCatalog.all
    assert_predicate BrokerCatalog.all, :frozen?
  end

  test "names returns sorted list" do
    names = BrokerCatalog.names

    assert_includes names, "BTG Pactual"
    assert_includes names, "Inter"
    assert_equal names, names.sort
  end

  test "valid? returns true for known broker" do
    assert BrokerCatalog.valid?("BTG Pactual")
    assert BrokerCatalog.valid?("Inter")
  end

  test "valid? returns false for unknown broker" do
    assert_not BrokerCatalog.valid?("Unknown Broker")
  end

  test "info returns type for known broker" do
    info = BrokerCatalog.info("BTG Pactual")

    assert_equal "full_service", info[:type]
  end

  test "info returns other for unknown broker" do
    info = BrokerCatalog.info("My Custom Broker")

    assert_equal "other", info[:type]
  end
end
