require 'rubygems'

spork = ENV['spork'] || /\bspork$/ =~ $0 ? true : false

prefork = lambda do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../dummy/config/environment", __FILE__)
  require 'rspec/rails'

  require 'vcr'
  require 'sunspot-rails-tester'

  begin
    require 'simplecov'
    require 'simplecov-rcov'

    SimpleCov.start 'rails' do
      add_filter do |source_file|
        source_file.lines.count < 5
      end
    end
    SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

  rescue LoadError
  end

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[EnjuTrunk::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

  $original_sunspot_session = Sunspot.session
  Sunspot::Rails::Tester.start_original_sunspot_session if spork

  RSpec.configure do |config|
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{EnjuTrunk::Engine.root}/spec/fixtures"
    FactoryGirl.definition_file_paths = ["#{EnjuTrunk::Engine.root}/spec/factories"]
    FactoryGirl.find_definitions

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = "random"

    config.before do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new($original_sunspot_session)

      PaperTrail.controller_info = {}
      PaperTrail.whodunnit = nil

      if defined?(SimpleCov)
        SimpleCov.command_name "RSpec:#{Process.pid.to_s}#{ENV['TEST_ENV_NUMBER']}"
      end
    end

    config.before :each, :solr => true do
      Sunspot::Rails::Tester.start_original_sunspot_session unless spork
      Sunspot.session = $original_sunspot_session
      Sunspot.remove_all!
    end

    config.extend ControllerMacros, :type => :controller

    config.extend VCR::RSpec::Macros
  end
end

each_run = lambda do
end

# https://github.com/burke/zeus/wiki/Spork
if spork
  # run under spork
  require 'spork'
  #uncomment the following line to use spork with the debugger
  #require 'spork/ext/ruby-debug'

  Spork.prefork(&prefork)
  Spork.each_run(&each_run)

elsif defined?(Zeus)
  # run under zeus
  prefork.call
  $each_run = each_run
  class << Zeus.plan
    def after_fork_with_test
      after_fork_without_test
      $each_run.call
    end
    alias_method_chain :after_fork, :test
  end

else
  prefork.call
  each_run.call
end
