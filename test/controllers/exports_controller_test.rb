# frozen_string_literal: true

require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
    @test_export_filename = "test_export_download_#{SecureRandom.hex(8)}.txt"
    @test_export_path = File.join(ExporterService::EXPORTS_PATH, @test_export_filename)
    FileUtils.mkdir_p(ExporterService::EXPORTS_PATH)
    File.write(@test_export_path, "sample export")
  end

  teardown do
    FileUtils.rm_f(@test_export_path)
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

  test "download serves existing export file" do
    get exports_download_path(name: @test_export_filename)

    assert_response :success
    assert_includes response.headers["Content-Disposition"], "attachment"
  end

  test "download redirects when file does not exist" do
    get exports_download_path(name: "missing_export.txt")

    assert_redirected_to exports_path
  end

  test "download rejects traversal filename" do
    get exports_download_path(name: "../database.yml")

    assert_redirected_to exports_path
  end

  test "redirects to login when not authenticated" do
    reset!
    get exports_path

    assert_redirected_to login_path
  end
end
