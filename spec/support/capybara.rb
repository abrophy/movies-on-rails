require "capybara/rspec"

# Use a real (headless) browser for system specs so Turbo/JS navigation runs.
Capybara.server = :puma
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5

# Skip system specs when Chrome isn't installed, so the rest of the suite still
# runs on machines without a browser.
def chrome_available?
  candidates = [
    ENV["CHROME_BIN"],
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/google-chrome-stable",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "/snap/bin/chromium"
  ]
  candidates.compact.any? { |path| File.exist?(path) }
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    skip "Chrome is not installed; skipping system specs" unless chrome_available?
  end
end
