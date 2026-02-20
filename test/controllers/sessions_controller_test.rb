require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "create via omniauth callback" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "test_uid_123",
      info: { email: "new@test.com", name: "New User", image: "https://example.com/pic.jpg" },
    )

    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path
    assert_predicate session[:user_id], :present?
  end

  test "destroy clears session" do
    login_as users(:alice)
    delete logout_path

    assert_redirected_to login_path
  end

  test "failure redirects to login" do
    get "/auth/failure", params: { message: "invalid_credentials" }

    assert_redirected_to login_path
  end
end
