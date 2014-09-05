namespace :enju_trunk do
  namespace :pack do
    desc 'Initial packing'
    task :init => :environment do
      enju_trunk_root_dir = Gem::Specification.find_by_name("enju_trunk").gem_dir
      require File.join(enju_trunk_root_dir, "lib/enju_trunk/enju_package")

      Rails.logger = Logger.new(STDOUT);
      Rails.logger.info "start script"

      manager = EnjuPackage.new

#      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ report/ script/ solr/ spec/ vendor/fonts vendor/cache/ vendor/assets/ report/)
      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ script/ solr/ vendor/cache/)

      unless EnjuPackage.generate_gitlastlog
        Rails.logger.warn "warn: not git repository." 
        archives.delete("GitLastLog")
      end

      unless FileTest::directory?(File.join(current_dir, ["vendor", "cache"]))
        Rails.logger.warn("warn: not find directory 'vendor/cache'. exec? 'bundle package --all'")
        Rails.logger.warn("warn: continue? (Y/N)")
        abort("abort task.") unless manager.question_yes_or_no
        archives.delete("vendor/cache/")
      end

      package_name = "#{manager.pack_prefix}_pack_staging_init.tar.bz2"
      package_file = File.join(manager.package_dir, package_name)

      unless FileTest::directory?(File.join(manager.package_dir))
        puts "warn: directory create? (Y/N) (#{manager.package_dir})"
        abort("abort task.") unless manager.question_yes_or_no
        FileUtils.mkdir_p(manager.package_dir)
      end

      manager.pack(package_file, archives)

      Rails.logger.info "success: #{package_file} md5digest=#{Digest::MD5.file(package_file).to_s}"
    end

    desc 'Packaging for staging server'
    task :staging => :environment do
      enju_trunk_root_dir = Gem::Specification.find_by_name("enju_trunk").gem_dir
      require File.join(enju_trunk_root_dir, "lib/enju_trunk/enju_package")

      Rails.logger = Logger.new(STDOUT);

      manager = EnjuPackage.new

      archives = %w(Gemfile Gemfile.lock GitLastLog Rakefile app/ db/fixtures/ solr/conf/ config/locales/ config/routes.rb db/ lib/ public/ script/ vendor/cache/)

      unless EnjuPackage.generate_gitlastlog
        Rails.logger.warn "warn: not git repository." 
        archives.delete("GitLastLog")
      end

      unless FileTest::directory?(File.join(current_dir, ["vendor", "cache"]))
        Rails.logger.warn("warn: not find directory 'vendor/cache'. exec? 'bundle package --all'")
        Rails.logger.warn("warn: continue? (Y/N)")
        abort("abort task.") unless manager.question_yes_or_no
        archives.delete("vendor/cache/")
      end

      package_name = "#{manager.pack_prefix}_pack_staging_#{Time.now.strftime('%Y%m%d%H%M%S')}.tar.bz2"
      package_file = File.join(manager.package_dir, package_name)

      manager.pack(package_file, archives)

      Rails.logger.info "success: #{package_file} md5digest=#{Digest::MD5.file(package_file).to_s}"
    end
  end
end

