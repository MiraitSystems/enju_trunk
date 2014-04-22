class EnjuTrunk::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  def copy_files
    directory 'db/fixtures', 'db/fixtures/enju_trunk'
    directory 'public', 'public'
    directory 'solr', 'solr'

    %w(
      config/sitemap.rb
      config/config.yml
      config/schedule.rb
      config/nacsis_client.yml.sample
      config/oai_cache.yml
      config/s3.yml.sample
      config/sitemap.rb
      config/unicorn.rb.sample
      config/initializers/delayed_job_config.rb
      config/initializers/ldap_authenticatable.rb.sample
      config/initializers/rack_protection.rb
      config/initializers/railties_order.rb
      db/seeds.rb
    ).each do |file|
      copy_file file, file
    end
  end

  def install_migrations
    %w(
      jpp_customercode_transfer
      enju_event_engine
      enju_trunk_engine
      enju_manifestation_viewer_engine
    ).each do |name|
      rake "#{name}:install:migrations"
    end
  end

  def fixup_migration_encoding
    pattern = %r!\A(\# This migration comes from .* \(originally \d+\)\n)(#.*encoding.*\n)!

    Dir.glob('db/migrate/*.rb') do |mf|
      content = File.read(mf)
      next unless pattern =~ content

      gsub_file mf, pattern, '\2\1'
    end
  end

  def setup_sunspot_rails
    solr_name = 'apache-solr-3.6.2'
    solr_dir = "vendor/#{solr_name}"
    solr_url = "http://archive.apache.org/dist/lucene/solr/3.6.2/#{solr_name}.tgz"
    solr_md5 = 'e9c51f51265b070062a9d8ed50b84647'
    solr_sha1 = '3a1a40542670ea6efec246a081053732c5503ec1'

    Dir.mktmpdir do |td|
      tgz_path = "#{td}/#{solr_name}.tgz"

      say "Getting #{solr_name} from #{solr_url}..."
      get solr_url, tgz_path, verbose: true
      unless Digest::MD5.file(tgz_path).to_s == solr_md5 &&
          Digest::SHA1.file(tgz_path).to_s == solr_sha1
        raise "failed to get #{solr_url}"
      end

      inside File.dirname(solr_dir) do
        run "tar xzf '#{tgz_path}'"
      end
    end unless File.exist?(solr_dir)

    generate 'sunspot_rails:install'
    gsub_file 'config/sunspot.yml', /^  solr:\n/, <<-E
  solr:
    solr_jar: #{solr_dir}/example/start.jar
    E
  end

  def setup_kaminari
    generate 'kaminari:config'
  end

  def setup_devise
    generate 'devise:install'

    route "devise_for :users, path: 'accounts'"
    route <<-E
devise_scope :user do
    match '/opac' => 'opac#index'
  end
    E

    gsub_file 'config/initializers/devise.rb', /^(\s*)\# (config\.authentication_keys) = \[ .*\n/, <<-'E'
\1\2 = [ :username ]
    E
  end

  def setup_delayed_job
    generate 'delayed_job:active_record'
  end

  def fixup_config_application
    target = 'config/application.rb'

    gsub_file target, /^(\s*)\# (config\.active_record\.observers) = .*\n/, <<-'E'
\1unless File.basename($0) == "rake" && ARGV.include?('db:migrate')
\1  \2 = :agent_sweeper, :page_sweeper, :item_sweeper,
\1    :manifestation_sweeper, :library_group_sweeper, :user_sweeper
\1end
    E

    gsub_file target, /^(\s*)\# (config\.time_zone) = .*\n/, <<-'E'
\1\2 = 'Tokyo'
    E

    gsub_file target, /^(\s*)\# (config\.i18n.default_locale) = .*\n/, <<-'E'
\1\2 = :ja
\1I18n.enforce_available_locales = true
    E

    gsub_file target, /^(\s*)(config\.filter_parameters) \+= \[:password\]\n/, <<-'E'
\1\2 += [
\1  :password, :full_name, :first_name, :middle_name, :last_name,
\1  :zip_code, :address_, :telephone_, :fax_, :birth_date, :death_date
\1]
    E

    comment_lines target, /^\s*config\.active_support\.escape_html_entities_in_json = true/
    comment_lines target, /^\s*config\.active_record\.whitelist_attributes = true/
  end

  def fixup_config_environments_production
    target = 'config/environments/production.rb'

    gsub_file target, /^(\s*)# (config\.logger) = .*\n/, <<-'E'
\1\2 = Logger.new("log/production.log", 'daily')
    E

    gsub_file target, /^(\s*)# (config\.cache_store) = .*\n/, <<-'E'
\1\2 = :dalli_store, {namespace: 'ENJUAPP', compress: true, expires_in: 1.day}
    E

    gsub_file target, /^(\s*)# (config\.assets\.precompile) \+= .*\n/, <<-'E'
\1\2 += %w( mobile.js mobile.css print.css )
    E

    insert_into_file target, <<-'E', before: /^end\s*\z/

  config.colorize_logging = false

  # config.action_mailer.default_url_options = { :host => 'localhost:3000' }
    E
  end

  def fixup_config_environments_development
    target = 'config/environments/development.rb'

    insert_into_file target, <<-'E', before: /^end\s*\z/

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
    E
  end

  def fixup_config_environments_test
    target = 'config/environments/test.rb'

    comment_lines target, /^\s*config.active_record.mass_assignment_sanitizer = :strict/

    insert_into_file target, <<-'E', before: /^end\s*\z/

  config.active_record.whitelist_attributes = false
    E
  end

  def fixup_config_initializers_session_store
    target = 'config/initializers/session_store.rb'

    gsub_file target, /^(.*::Application\.config\.session_store) :cookie_store, (?:key:|:key =>) '(.*)'\n/, <<-'E'
require 'action_dispatch/middleware/session/dalli_store'
\1 :dalli_store, key: '\2'
    E
  end

  def fixup_application_controller
    inject_into_class 'app/controllers/application_controller.rb', ApplicationController, <<-'E'
  include EnjuTrunk::EnjuTrunkController
    E
  end

  def fixup_application_helper
    insert_into_file 'app/helpers/application_helper.rb', <<-'E', after: /ApplicationHelper\n/
  include EnjuTrunk::EnjuTrunkHelper
    E
  end

  def fixup_public_files
    remove_file 'public/index.html'
  end
end
