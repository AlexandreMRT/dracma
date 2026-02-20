# frozen_string_literal: true

require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
  end

  test "index lists export files" do
    get exports_path

    assert_response :success
  end

  test "csv exports when quotes exist" do
    get exports_csv_path
    # With fixture quotes, it should either send a file (200) or redirect (302)
    assert_includes [ 200, 302 ], response.status
  end

  test "json exports when quotes exist" do
    get exports_json_path

    assert_includes [ 200, 302 ], response.status
  end

  test "report generates reports" do
    # Stub the polymarket call that generates_reports makes
    stub_request(:get, /gamma-api\.polymarket\.com/).to_return(
      status: 200, body: "[]", headers: { "Content-Type" => "application/json" }
    )
    get exports_report_path

    assert_redirected_to exports_path
  end

  test "redirects to login when not authenticated" do
    reset!
    get exports_path

    assert_redirected_to login_path
  end
end
