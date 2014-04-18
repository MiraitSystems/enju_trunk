# http://railspress.matake.jp/extend-plugin-gem-library-in-rails-project
require File.expand_path(File.join(File.dirname(__FILE__), 'plugins', 'ext'))

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
 
