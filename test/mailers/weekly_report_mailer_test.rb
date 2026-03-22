# frozen_string_literal: true

require "test_helper"

class WeeklyReportMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:alice)
    @orig_latest_rows = ExporterService.method(:latest_rows)
    ExporterService.define_singleton_method(:latest_rows) { |**| [] }
  end

  teardown do
    ExporterService.define_singleton_method(:latest_rows, @orig_latest_rows)
  end

  test "sends to the user's email address" do
    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_equal [ @user.email ], mail.to
  end

  test "subject contains weekly market summary" do
    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_match "Weekly Market Summary", mail.subject
  end

  test "subject contains current week label" do
    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_match Date.current.strftime("%Y"), mail.subject
  end

  test "html body includes user name" do
    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_match @user.name, mail.html_part.body.to_s
  end

  test "text body includes user name" do
    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_match @user.name, mail.text_part.body.to_s
  end

  test "renders successfully with no market data" do
    assert_emails 1 do
      WeeklyReportMailer.weekly_summary(@user).deliver_now
    end
  end

  test "html body shows top gainers section" do
    row = {
      ticker: "PETR4", tipo: "stock", var_1w: 5.2, signal_summary: "bullish",
      ibov_change_ytd: 3.1, sp500_change_ytd: 2.0
    }
    ExporterService.define_singleton_method(:latest_rows) { |**| [ row ] }

    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_match "PETR4", mail.html_part.body.to_s
    assert_match "+5.2%", mail.html_part.body.to_s
  end

  test "html body shows market overview with ibov ytd" do
    row = {
      ticker: "PETR4", tipo: "stock", var_1w: 2.0, signal_summary: nil,
      ibov_change_ytd: 7.5, sp500_change_ytd: 4.2
    }
    ExporterService.define_singleton_method(:latest_rows) { |**| [ row ] }

    mail = WeeklyReportMailer.weekly_summary(@user)

    assert_match "IBOV YTD", mail.html_part.body.to_s
    assert_match "+7.5%", mail.html_part.body.to_s
  end
end
