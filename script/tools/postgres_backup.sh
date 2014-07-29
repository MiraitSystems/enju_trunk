#!/usr/bin/env ruby

require 'yaml'

backupdir = "/backup/db"
user = "postgres"
rails_env = ENV['RAILS_ENV'] || 'production'
configfile = File.expand_path('../../../config/database.yml', __FILE__)
config = YAML.load_file(configfile)
dbname = config[rails_env]["database"] rescue "enju_production"

dumpfilename = "pgdump.#{dbname}.#{Time.now.strftime('%Y%m%d%H%M%S')}.custom"
pg_dump = "/usr/bin/pg_dump"

dumpfile = "#{backupdir}/#{dumpfilename}"

#LD_LIBRARY_PATH=/usr/local/pgsql/lib
#export LD_LIBRARY_PATH

puts "backup start db:#{dbname} file: #{dumpfile}"

system("#{pg_dump} -U #{user} #{dbname} -Fc > #{dumpfile}")

puts "done."

