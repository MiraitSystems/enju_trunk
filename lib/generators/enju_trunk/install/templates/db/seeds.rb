# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# Change the following
username = 'admin'
email = 'admin@example.jp'
password = 'adminpassword'

# Don't edit!
require 'active_record/fixtures'

unless solr = Sunspot.commit rescue nil
  raise "Solr is not running."
end

Dir.glob(Rails.root.to_s + '/db/fixtures/**/*.yml').each do |file|
  file = file.sub(/\A#{Regexp.quote(Rails.root.to_s)}\/+/, '')
  ActiveRecord::Fixtures.create_fixtures(
    File.dirname(file), File.basename(file, '.*'))
end

Agent.reindex
Library.reindex

user = User.find(1)
user.username = username
user.email = email
user.password = password
user.password_confirmation = password
user.role = Role.find_by_name('Administrator')
user.function_class = FunctionClass.find_by_name('admin')
user.operator = user
user.save!
#user.confirm!
user.index!
puts 'Administrator account created.'

# sample
user = User.find(2)
user.password = "enjuenju"
user.password_confirmation = "enjuenju"
user.role = Role.find_by_name('Librarian')
user.function_class = FunctionClass.find_by_name('librarian')
user.operator = user
user.save!
user = User.find(3)
user.password = "enjuenju"
user.password_confirmation = "enjuenju"
user.role = Role.find_by_name('Librarian')
user.function_class = FunctionClass.find_by_name('librarian')
user.operator = user
user.save!
user = User.find(4)
user.password = "enjuenju"
user.password_confirmation = "enjuenju"
user.role = Role.find_by_name('Librarian')
user.function_class = FunctionClass.find_by_name('librarian')
user.operator = user
user.save!
user = User.find(5)
user.password = "enjuenju"
user.password_confirmation = "enjuenju"
user.role = Role.find_by_name('Librarian')
user.function_class = FunctionClass.find_by_name('librarian')
user.operator = user
user.save!
puts 'demo account created.'
