# frozen_string_literal: true

module Api
  class SectorsController < BaseController
    def index
      sectors = ApiDataService.sector_performance
      render_json({ total: sectors.size, sectors: sectors })
    end
  end
end
