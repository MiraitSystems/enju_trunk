source "https://rubygems.org"

# Declare your gem's dependencies in xenju_trunk_engine.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'

# For the dummy application
gem 'pg'
gem 'thinreports', git: 'git://github.com/emiko/thinreports-generator.git'
gem 'select2-rails', git: 'git://github.com/MiraitSystems/select2-rails.git'
gem 'enju_trunk_event', git: 'git://github.com/MiraitSystems/enju_trunk_event.git', require: 'enju_event'
gem 'enju_ndl', git: 'git://github.com/MiraitSystems/enju_trunk_ndl.git'
gem 'enju_trunk_frbr', git: 'git://github.com/emiko/enju_trunk_frbr.git'

group :optional do
  gem 'enju_trunk_circulation', git: 'git://github.com/MiraitSystems/enju_trunk_circulation.git'
  gem 'enju_trunk_ill', git: 'git://github.com/MiraitSystems/enju_trunk_ill.git'
  gem 'enju_trunk_statistics', git: 'git://github.com/MiraitSystems/enju_trunk_statistics.git'
  gem 'enju_book_jacket', '0.1.0.pre2'
  gem 'enju_message', :git => 'git://github.com/MiraitSystems/enju_trunk_message.git'
end
