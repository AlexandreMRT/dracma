# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :require_login

    private

    def render_json(data, status: :ok)
      render json: data, status: status
    end
  end
end
