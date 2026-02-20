require "test_helper"

class AssetTest < ActiveSupport::TestCase
  test "valid asset" do
    assert assets(:petr4).valid?
  end

  test "requires ticker" do
    asset = Asset.new(name: "Test", sector: "test", asset_type: "stock")
    assert_not asset.valid?
    assert_includes asset.errors[:ticker], "can't be blank"
  end

  test "requires unique ticker" do
    asset = Asset.new(ticker: assets(:petr4).ticker, name: "Dup", sector: "test", asset_type: "stock")
    assert_not asset.valid?
  end

  test "has many quotes" do
    assert_respond_to assets(:petr4), :quotes
  end
end
