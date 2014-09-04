dir_prefix = "customer"
if ENV["ENJU_CUSTOMER_PREFIX"]
	dir_prefix = ENV["ENJU_CUSTOMER_PREFIX"]
  puts "set prefix=#{dirprefix}"
end

base_dir = ENV['HOME']

package_dir = File.join(base_dir, dir_prefix, "pack")
packprefix = "enju_production"
root = "#{::Rails.root}"

def packing(packagefile, archives, excludes = "")
  #sh "cd #{::Rails.root}; bundle package --all"
  sh "cd #{::Rails.root}; tar cjvf #{packagefile} #{archives} --exclude #{excludes}"
end

namespace :enju_trunk do
  namespace :pack do
    desc 'Initial packing'
    task :init => :environment do

      Rails.logger.info "start script"

#      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ report/ script/ solr/ spec/ vendor/fonts vendor/cache/ vendor/assets/ report/)
      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ script/ solr/ vendor/cache/)

      current_dir = "#{::Rails.root}"
      if FileTest::directory?(File.join(current_dir, ".git"))
        sh "cd #{::Rails.root}; git log -1 > GitLastLog"
      else 
        Rails.logger.info "not git repository." 
        archives.delete("GitLastLog")
      end

      unless FileTest::directory?(File.join(current_dir, ["vendor", "cache"]))
        archives.delete("vendor/cache/")
      end

      package_name = "#{packprefix}_pack_staging_init.tar.bz2"
      packagefile = "#{package_dir}#{package_name}"
      exclude_from = "script/tools/exclude_init"

      unless FileTest::directory?(File.join(package_dir))
        puts "create directory ? (#{package_dir})"
        FileUtils.mkdir_p(package_dir)
      end

      #packing
      sh "cd #{::Rails.root}; tar cjvf #{packagefile} #{archives.join(' ')} -X #{exclude_from}"

      Rails.logger.info "success: #{packagefile} md5digest=#{Digest::MD5.file(packagefile).to_s}"
    end

    desc 'Packaging for staging server'
    task :staging => :environment do
      sh "cd #{::Rails.root}; git log -1 > GitLastLog"
#      archives = "Gemfile Gemfile.lock GitLastLog Rakefile app/ db/fixtures/ solr/conf/ config/locales/ config/routes.rb db/ lib/ public/ script/ vendor/fonts vendor/cache/ config/initializers/thinreports.rb config/initializers/*.sample config/*.sample"
      archives = "Gemfile Gemfile.lock GitLastLog Rakefile app/ db/fixtures/ solr/conf/ config/locales/ config/routes.rb db/ lib/ public/ script/ vendor/cache/"

      package_name = "#{packprefix}_pack_staging_#{Time.now.strftime('%Y%m%d%H%M%S')}.tar.bz2"
      packagefile = "#{package_dir}#{package_name}"

      exclude_from = "script/tools/exclude_init"
      sh "cd #{::Rails.root}; tar cjvf #{packagefile} #{archives} -X #{exclude_from}"
    end
  end
end
