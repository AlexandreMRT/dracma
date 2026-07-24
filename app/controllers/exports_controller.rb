# frozen_string_literal: true

class ExportsController < ApplicationController
  def index
    @exports = available_exports
  end

  def download
    file_name = params[:name].to_s
    export = available_exports.find { |entry| entry[:name] == file_name }

    if export
      send_file export[:path], disposition: "attachment"
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

  def available_exports
    Dir.glob(File.join(ExporterService::EXPORTS_PATH, "*")).filter_map do |path|
      safe_path = safe_export_path(File.basename(path))
      next unless safe_path

      {
        name: File.basename(safe_path),
        path: safe_path,
        size: File.size(safe_path),
        mtime: File.mtime(safe_path)
      }
    end.sort_by { |entry| -entry[:mtime].to_i }
  end
end
