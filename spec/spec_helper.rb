require 'rubygems'

# Loading more in this block will cause your tests to run faster. However,
# if you change any configuration or code from libraries loaded here, you'll
# need to restart spork for it take effect.
ENV["RAILS_ENV"] ||= 'test'

# Dependencies
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'email_spec'
require 'warden'

require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'capybara/poltergeist'
require 'database_cleaner'

RSpec.configure do |config|
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Use DatabaseCleaner to handle test data. On JS specs (running on Selenium)
  # transactional fixtures aren't supported, so we don't use them. On all
  # other specs we do, because they're faster.
  config.use_transactional_fixtures = false

  # Configure Warden to allow quick logins for feature specs.
  config.include Warden::Test::Helpers
  config.after(:each) { Warden.test_reset! }

  # Use Devise helpers for controller specs.
  config.include Devise::TestHelpers, :type => :controller

  config.before(:each) do
    # If running a spec with JS, there will be multiple processes handling the
    # database and so running the spec within a transaction is not supported.
    # Otherwise, we use transactions because they're faster.
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end

# Preload some heavier modules that we depend on to speed up testing further.
require 'rspec/mocks'
require 'rspec/core/mocking/with_rspec'
require 'rspec/mocks/framework'

# Headless JS tests with Capybara.
# Using :selenium is slower, but you get to watch the test in an actual browser.
# Note that this will only run on specs that have :js => true.
Capybara.register_driver :poltergeist_debug do |app|
  # Supports remote inspection; see http://www.jonathanleighton.com/articles/2012/poltergeist-0-6-0/
  Capybara::Poltergeist::Driver.new(app, :inspector => true)
end
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end
Capybara.javascript_driver = :poltergeist
# Capybara.javascript_driver = :poltergeist_debug
# Capybara.javascript_driver = :selenium

FactoryGirl.reload
DatabaseCleaner.strategy = :truncation
Warden.test_mode!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
