ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Path to a CSV fixture under test/fixtures/csv/.
    def csv_fixture(name)
      Rails.root.join("test", "fixtures", "csv", name)
    end
  end
end
