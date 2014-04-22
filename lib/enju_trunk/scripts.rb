# encoding: utf-8
script_name = File.basename($0)
script = File.expand_path("../scripts/#{script_name}.rb", __FILE__)

unless File.exist?(script)
  warn "script `#{script_name}' is not known"
  exit(101)
end

ENV['RAILS_ENV'] ||= 'production'
exec('bundle', 'exec', 'rails', 'runner', script, '--', *ARGV)
