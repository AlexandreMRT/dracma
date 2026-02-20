# frozen_string_literal: true

require "test_helper"

class AssetCatalogTest < ActiveSupport::TestCase
  test "all returns hash of ticker to info" do
    all = AssetCatalog.all

    assert_kind_of Hash, all
    assert_operator all.size, :>, 100
    assert all.key?("PETR4.SA")
    assert_kind_of Hash, all["PETR4.SA"]
    assert_includes all["PETR4.SA"].keys, :name
  end

  test "asset_type_for known tickers" do
    assert_equal "stock", AssetCatalog.asset_type_for("PETR4.SA")
    assert_equal "us_stock", AssetCatalog.asset_type_for("AAPL")
    assert_equal "commodity", AssetCatalog.asset_type_for("GC=F")
    assert_equal "crypto", AssetCatalog.asset_type_for("BTC-USD")
    assert_equal "currency", AssetCatalog.asset_type_for("USDBRL=X")
  end

  test "brazilian? returns true for .SA tickers" do
    assert AssetCatalog.brazilian?("PETR4.SA")
    assert_not AssetCatalog.brazilian?("AAPL")
  end

  test "info returns hash for known ticker" do
    info = AssetCatalog.info("PETR4.SA")

    assert_equal "Petrobras PN", info[:name]
    assert_equal "Petróleo e Gás", info[:sector]
  end

  test "info returns fallback for unknown ticker" do
    info = AssetCatalog.info("UNKNOWN123")

    assert_equal "Desconhecido", info[:name]
    assert_equal "Outro", info[:sector]
  end
end
