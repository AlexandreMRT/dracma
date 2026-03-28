require "uri"

oauth_options = {
  prompt: "select_account",
  image_aspect_ratio: "square",
  image_size: 50
}

# OAUTH_REDIRECT_URI should be a full HTTP(S) URL including the callback path,
# for example: http://localhost:3000/auth/google_oauth2/callback.
oauth_redirect_uri = ENV["OAUTH_REDIRECT_URI"].to_s.strip

unless oauth_redirect_uri.empty?
  begin
    parsed_uri = URI.parse(oauth_redirect_uri)
    scheme = parsed_uri.scheme.to_s.downcase
    host = parsed_uri.host.to_s
    path = parsed_uri.path.to_s

    if scheme.empty? || !%w[http https].include?(scheme) || host.empty? || path.empty? || !path.start_with?("/")
      Rails.logger.warn("Invalid OAUTH_REDIRECT_URI (must be absolute HTTP(S) URL with host and callback path starting with '/'); using default OmniAuth callback path")
    else
      oauth_options[:redirect_uri] = oauth_redirect_uri
      oauth_options[:callback_path] = path
    end
  rescue URI::InvalidURIError => e
    Rails.logger.warn("Invalid OAUTH_REDIRECT_URI; using default OmniAuth callback path (#{e.message})")
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], oauth_options
end
OmniAuth.config.allowed_request_methods = %i[get post]
