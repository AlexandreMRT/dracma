# frozen_string_literal: true

namespace :export do
  desc "Export quotes to CSV"
  task csv: :environment do
    filepath = ExporterService.export_csv
    puts(filepath ? "CSV exported to #{filepath}" : "No quote data available")
  end

  desc "Export quotes to JSON"
  task json: :environment do
    filepath = ExporterService.export_json
    puts(filepath ? "JSON exported to #{filepath}" : "No quote data available")
  end

  desc "Generate Markdown and AI reports"
  task report: :environment do
    human_path, ai_path = ExporterService.generate_reports

    if human_path || ai_path
      puts "Markdown report: #{human_path}" if human_path
      puts "AI report: #{ai_path}" if ai_path
    else
      puts "No quote data available"
    end
  end
end
