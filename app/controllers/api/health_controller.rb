# frozen_string_literal: true

module Api
  class HealthController < BaseController
    def data
      render_json(DataHealthChecker.report)
    end
  end
end
