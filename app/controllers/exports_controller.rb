# frozen_string_literal: true

class ExportsController < ApplicationController
  def index
    @exports = Dir.glob(File.join(ExporterService::EXPORTS_PATH, "*"))
                  .map { |f| { name: File.basename(f), size: File.size(f), mtime: File.mtime(f) } }
                  .sort_by { |e| -e[:mtime].to_i }
  end

  def download
    file_name = params[:name].to_s
    path = safe_export_path(file_name)

    if path && File.file?(path)
      send_file path, disposition: "attachment"
    else
      redirect_to exports_path, alert: "Export file not found"
    end
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

  def safe_export_path(file_name)
    return nil if file_name.blank?
    return nil unless file_name == File.basename(file_name)

    exports_root = File.expand_path(ExporterService::EXPORTS_PATH)
    candidate = File.expand_path(File.join(exports_root, file_name))
    return nil unless candidate.start_with?("#{exports_root}/")
    return nil unless File.exist?(candidate)
    return nil if File.symlink?(candidate)

    real_candidate = File.realpath(candidate)
    return nil unless real_candidate.start_with?("#{exports_root}/")

    real_candidate
  rescue Errno::ENOENT, Errno::EACCES, Errno::EINVAL
    nil
  end
end
