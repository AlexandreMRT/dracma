require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Simulate Google OAuth login for system tests.
  # OmniAuth test mode intercepts the callback path and injects the mock auth hash.
  def sign_in_as(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: user.google_id,
      info: { email: user.email, name: user.name, image: user.picture_url },
    )
    visit "/auth/google_oauth2/callback"
  end
end
