# frozen_string_literal: true

module Api
  class ReportController < BaseController
    def show
      data = ExporterService.report_data
      return render_error("No quote data available", status: :not_found) unless data

      render_json(data)
    end
  end
end
