# frozen_string_literal: true

# Define an application-wide permissions policy.
# Restricts access to browser features not needed by this application.
# See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy

Rails.application.configure do
  config.permissions_policy do |policy|
    policy.camera      :none
    policy.microphone  :none
    policy.geolocation :none
    policy.usb         :none
    policy.midi        :none
    policy.magnetometer :none
    policy.gyroscope :none
    policy.accelerometer :none
    policy.payment     :none
    policy.fullscreen  :self
  end
end
