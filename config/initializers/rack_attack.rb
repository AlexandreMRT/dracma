# frozen_string_literal: true

# Rack::Attack — Rate limiting and brute force protection
# See: https://github.com/rack/rack-attack

class Rack::Attack
  # --- Throttles ---

  # Limit login attempts: 5 requests per minute per IP
  throttle("auth/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path.start_with?("/auth")
  end

  # Limit API requests: 60 requests per minute per user session
  throttle("api/user", limit: 60, period: 60.seconds) do |req|
    if req.path.start_with?("/api")
      req.env["rack.session"]&.fetch("user_id", nil) || req.ip
    end
  end

  # Limit general requests: 300 requests per 5 minutes per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # --- Safelist ---

  # Allow localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # --- Custom Responses ---

  self.throttled_responder = lambda do |_matched, _env|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Rate limit exceeded. Retry later." }.to_json ]
    ]
  end
end
