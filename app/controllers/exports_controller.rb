# frozen_string_literal: true

class ExportsController < ApplicationController
  def index
    @exports = Dir.glob(File.join(ExporterService::EXPORTS_PATH, "*"))
                  .map { |f| { name: File.basename(f), size: File.size(f), mtime: File.mtime(f) } }
                  .sort_by { |e| -e[:mtime].to_i }
  end

  def csv
    path = ExporterService.export_csv(quote_date: parse_date)
    if path
      send_file path, type: "text/csv", disposition: "attachment"
    else
      redirect_to exports_path, alert: "No quotes found to export"
    end
  end

  def json
    path = ExporterService.export_json(quote_date: parse_date)
    if path
      send_file path, type: "application/json", disposition: "attachment"
    else
      redirect_to exports_path, alert: "No quotes found to export"
    end
  end

  def report
    human, ai = ExporterService.generate_reports
    if human
      redirect_to exports_path, notice: "Reports generated successfully"
    else
      redirect_to exports_path, alert: "No data available for report"
    end
  end

  private

  def parse_date
    params[:date] ? Date.parse(params[:date]) : nil
  rescue Date::Error
    nil
  end
end
