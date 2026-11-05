require "capybara/rspec"

# Use a real (headless) browser for system specs so Turbo/JS navigation runs.
Capybara.server = :puma
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5
