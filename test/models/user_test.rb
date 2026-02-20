require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = users(:alice)

    assert_predicate user, :valid?
  end

  test "requires google_id" do
    user = User.new(email: "test@test.com", name: "Test")

    assert_not user.valid?
    assert_includes user.errors[:google_id], "can't be blank"
  end

  test "requires unique email" do
    user = User.new(google_id: "new123", email: users(:alice).email, name: "Dup")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "from_omniauth creates new user" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "new_google_id",
      info: { email: "newuser@test.com", name: "New User", image: "https://example.com/pic.jpg" },
    )
    user = User.from_omniauth(auth)
    user.save!

    assert_predicate user, :persisted?
    assert_equal "new_google_id", user.google_id
    assert_equal "newuser@test.com", user.email
  end

  test "from_omniauth finds existing user" do
    alice = users(:alice)
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: alice.google_id,
      info: { email: alice.email, name: "Alice Updated", image: "https://example.com/new.jpg" },
    )
    user = User.from_omniauth(auth)
    user.save!

    assert_equal alice.id, user.id
    assert_equal "Alice Updated", user.name
  end

  test "has many watchlists" do
    assert_respond_to users(:alice), :watchlists
  end

  test "has many portfolios" do
    assert_respond_to users(:alice), :portfolios
  end
end
