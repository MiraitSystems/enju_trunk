$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "enju_trunk/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enju_trunk"
  s.version     = EnjuTrunk::VERSION
  s.authors     = ["EnjuTrunk authors"]
  s.email       = ["EnjuTrunk@example.jp"]
  s.homepage    = "http://example.jp"
  s.summary     = "Summary of EnjuTrunk."
  s.description = "Description of EnjuTrunk."

  s.files         = `git ls-files`.split(/\n/)
  s.test_files    = `git ls-files -- {test,spec}/*`.split(/\n/)
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f) }

  s.add_dependency "rails", "~> 3.2.17"
  s.add_dependency 'jquery-rails', "~> 3.0.4"
  s.add_dependency 'jquery-ui-rails', "~> 4.0.4"
  s.add_dependency 'rack-protection'
  s.add_dependency 'addressable'
  s.add_dependency 'delayed_job_active_record'
  s.add_dependency 'daemons'
  s.add_dependency 'sunspot_rails', '~> 2.0.0'
  s.add_dependency 'geocoder'
  s.add_dependency 'paper_trail', '~> 2.6'
  s.add_dependency 'simple_form', '~> 1.5'
  s.add_dependency 'validates_timeliness'
  s.add_dependency 'activerecord-import'
  s.add_dependency 'jpp_customercode_transfer', '~> 0.0.2'
  s.add_dependency 'roo', '= 1.10.1'
  s.add_dependency 'rubyzip', "= 0.9.9" # roo 1.10.1 depends on rubyzip 0.9.x (x >= 4)
  s.add_dependency 'axlsx', '~> 1.3.6'
  s.add_dependency 'spinjs-rails'
  s.add_dependency 'kaminari'
  s.add_dependency 'settingslogic'
  s.add_dependency 'state_machine'
  s.add_dependency 'progress_bar'
  s.add_dependency 'friendly_id', '~> 4.0'
  s.add_dependency 'has_scope'
  s.add_dependency 'inherited_resources', '~> 1.3'
  s.add_dependency 'acts-as-taggable-on', '~> 2.2'
  s.add_dependency 'dalli', '~> 2.6'
  s.add_dependency 'sitemap_generator', '~> 3.0'
  s.add_dependency 'file_wrapper'
  s.add_dependency 'redcarpet', '~> 3.1.1'
  s.add_dependency 'lisbn'
  s.add_dependency 'cancan', '>= 1.6.7'
  s.add_dependency 'devise', '~> 1.5'
  s.add_dependency 'paperclip', '2.8'
  s.add_dependency 'whenever', '~> 0.6'
  s.add_dependency 'dynamic_form'
  s.add_dependency 'attribute_normalizer', '~> 1.1'
  s.add_dependency 'barby', '~> 0.5'
  s.add_dependency 'chunky_png', '1.2.5'
  s.add_dependency 'rqrcode'
  s.add_dependency 'rghost', '0.9.3'
  s.add_dependency 'rghost_barcode'
  s.add_dependency 'acts_as_list'
  s.add_dependency 'library_stdnums'
  s.add_dependency 'client_side_validations'
  s.add_dependency 'prawn', '1.0.0.rc1'
  s.add_dependency 'rmagick'
  s.add_dependency 'rails_autolink'
  s.add_dependency 'parallel'
  s.add_dependency 'enju_subject', '0.1.0.pre5'
  s.add_dependency 'enju_manifestation_viewer', '0.1.0.pre3'
  s.add_dependency 'enju_oai', '0.1.0.pre5'

  s.add_development_dependency 'sunspot_solr', '~> 2.0.0'
  s.add_development_dependency 'sunspot-rails-tester'
  s.add_development_dependency 'parallel_tests'
  s.add_development_dependency 'annotate'
  s.add_development_dependency 'rspec-rails', '~> 2.9'
  s.add_development_dependency 'factory_girl_rails', '~> 3.0'
  s.add_development_dependency 'vcr', '~> 2.0.0.rc2'
  s.add_development_dependency 'ci_reporter'
end
