require 'rack-protection'
require 'delayed_job_active_record'
require 'geocoder'
require 'simple_form'
require 'validates_timeliness'
require 'activerecord-import'
require 'jpp_customercode_transfer'
require 'settingslogic'
require 'state_machine'
require 'friendly_id'
require 'has_scope'
require 'inherited_resources'
require 'acts-as-taggable-on'
require 'redcarpet'
require 'lisbn'
require 'cancan'
require 'devise'
require 'paperclip'
require 'dynamic_form'
require 'attribute_normalizer'
require 'barby'
require 'rghost'
require 'rghost_barcode'
require 'acts_as_list'
require 'library_stdnums'
require 'prawn'
require 'rails_autolink'
require 'jquery-ui-rails'
require 'select2-rails'
require 'spinjs-rails'
require 'client_side_validations'
require 'enju_subject'
require 'enju_leaf'
require 'enju_trunk/engine'
require 'enju_trunk/enju_trunk_controller'
require 'enju_trunk/resourceadapter'

begin
  require 'enju_trunk_circulation'
rescue LoadError
  warn $!
end

begin
  require 'enju_trunk_ill' 
rescue LoadError
  warn $!
end

begin
  require 'enju_trunk_statistics' 
rescue LoadError
  warn $!
end
 
module EnjuTrunk
end
