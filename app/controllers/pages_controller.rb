class PagesController < ApplicationController
  skip_before_action :require_login, only: [ :login ]

  def login
    redirect_to root_path if logged_in?

    @google_oauth_request_url = google_oauth_request_url
  end

  private

  def google_oauth_request_url
    redirect_uri = ENV["OAUTH_REDIRECT_URI"].to_s.strip
    return "/auth/google_oauth2" if redirect_uri.empty?

    begin
      parsed = URI.parse(redirect_uri)
      scheme = parsed.scheme.to_s.downcase
      host = parsed.host.to_s
      return "/auth/google_oauth2" unless %w[http https].include?(scheme) && host.present?

      port = parsed.port
      default_port = parsed.default_port
      host_with_port = port == default_port ? host : "#{host}:#{port}"

      "#{scheme}://#{host_with_port}/auth/google_oauth2"
    rescue URI::InvalidURIError
      "/auth/google_oauth2"
    end
  end
end
