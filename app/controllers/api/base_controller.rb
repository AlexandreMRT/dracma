# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :require_login

    private

    def render_json(data, status: :ok)
      render json: data, status: status
    end

    def render_error(message, status:)
      render_json({ error: message }, status: status)
    end

    def parse_limit(value, default:, max: 100)
      return default if value.blank?

      parsed = value.is_a?(Numeric) ? value.to_i : Integer(value.to_s, 10)
      return nil if parsed < 1

      [ parsed, max ].min
    rescue ArgumentError, TypeError
      nil
    end

    def parse_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
