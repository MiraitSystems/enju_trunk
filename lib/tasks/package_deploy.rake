dir_prefix = "customer"
if ENV["ENJU_CUSTOMER_PREFIX"]
	dir_prefix = ENV["ENJU_CUSTOMER_PREFIX"]
  #Rails.logger.info "set prefix=#{dirprefix}"
end

base_dir = ENV['HOME']

package_dir = File.join(base_dir, dir_prefix, "pack")
packprefix = "enju_production"
root = "#{::Rails.root}"

namespace :enju_trunk do
  namespace :pack do
    desc 'Initial packing'
    task :init => :environment do
      enju_trunk_root_dir = Gem::Specification.find_by_name("enju_trunk").gem_dir
      require File.join(enju_trunk_root_dir, "lib/enju_trunk/enju_package")

      Rails.logger = Logger.new(STDOUT);
      Rails.logger.info "start script"

#      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ report/ script/ solr/ spec/ vendor/fonts vendor/cache/ vendor/assets/ report/)
      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ script/ solr/ vendor/cache/)

      current_dir = "#{::Rails.root}"
      unless EnjuPackage.generate_gitlastlog(current_dir)
        Rails.logger.warn "warn: not git repository." 
        archives.delete("GitLastLog")
      end

      unless FileTest::directory?(File.join(current_dir, ["vendor", "cache"]))
        Rails.logger.warn("warn: not find directory 'vendor/cache'. exec? 'bundle package --all'")
        archives.delete("vendor/cache/")
      end

      package_name = "#{packprefix}_pack_staging_init.tar.bz2"
      packagefile = File.join(package_dir, package_name)
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
      enju_trunk_root_dir = Gem::Specification.find_by_name("enju_trunk").gem_dir
      require File.join(enju_trunk_root_dir, "lib/enju_trunk/enju_package")

      Rails.logger = Logger.new(STDOUT);

#      archives = "Gemfile Gemfile.lock GitLastLog Rakefile app/ db/fixtures/ solr/conf/ config/locales/ config/routes.rb db/ lib/ public/ script/ vendor/fonts vendor/cache/ config/initializers/thinreports.rb config/initializers/*.sample config/*.sample"
      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ db/fixtures/ solr/conf/ config/locales/ config/routes.rb db/ lib/ public/ script/ vendor/cache/)

      unless EnjuPackage.generate_gitlastlog
        Rails.logger.warn "warn: not git repository." 
        archives.delete("GitLastLog")
      end

      package_name = "#{packprefix}_pack_staging_#{Time.now.strftime('%Y%m%d%H%M%S')}.tar.bz2"
      packagefile = File.join(package_dir, package_name)

      exclude_from = "script/tools/exclude_init"
      sh "cd #{::Rails.root}; tar cjvf #{packagefile} #{archives.join(' ')} -X #{exclude_from}"

      Rails.logger.info "success: #{packagefile} md5digest=#{Digest::MD5.file(packagefile).to_s}"
    end
  end
end
