# frozen_string_literal: true

module Api
  class SignalsController < BaseController
    def index
      render_json(ApiDataService.signals_summary)
    end
  end
end
