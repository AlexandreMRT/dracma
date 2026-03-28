require "uri"

oauth_options = {
  prompt: "select_account",
  image_aspect_ratio: "square",
  image_size: 50
}

oauth_redirect_uri = ENV["OAUTH_REDIRECT_URI"].to_s.strip

unless oauth_redirect_uri.empty?
  begin
    parsed_uri = URI.parse(oauth_redirect_uri)

    if parsed_uri.path.to_s.empty?
      Rails.logger.warn("Invalid OAUTH_REDIRECT_URI (missing callback path); using default OmniAuth callback path")
    else
      oauth_options[:redirect_uri] = oauth_redirect_uri
      oauth_options[:callback_path] = parsed_uri.path
    end
  rescue URI::InvalidURIError => e
    Rails.logger.warn("Invalid OAUTH_REDIRECT_URI; using default OmniAuth callback path (#{e.message})")
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], oauth_options
end
OmniAuth.config.allowed_request_methods = %i[get post]
