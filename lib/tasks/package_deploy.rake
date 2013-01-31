package_dir = "/home/enju/jma/pack/"
packprefix = "enju_jma"
root = "#{::Rails.root}"

def packing(packagefile, archives, excludes = "")
  #sh "cd #{::Rails.root}; bundle package --all"
  sh "cd #{::Rails.root}; tar cjvf #{packagefile} #{archives} --exclude #{excludes}"
end

namespace :enju_trunk do
  namespace :pack do
    desc 'Initial packing'
    task :init => :environment do
      sh "cd #{::Rails.root}; git log -1 > GitLastLog"

      archives = "Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ config.ru db/ lib/ public/ report/ script/ spec/ vendor/fonts vendor/plugins/ vendor/cache/"

      package_name = "#{packprefix}_pack_staging_init_#{Time.now.strftime('%Y%m%d%H%M%S')}.tar.bz2"
      packagefile = "#{package_dir}#{package_name}"
      excludes = ".gitkeep *.sample"
      exclude_from = "exclude"
     
      #packing
      sh "cd #{::Rails.root}; tar cjvf #{packagefile} #{archives} -X #{exclude_from}"
    end

    desc 'Packaging for staging server'
    task :staging => :environment do
      sh "cd #{::Rails.root}; git log -1 > GitLastLog"
      archives = "Gemfile Gemfile.lock GitLastLog Rakefile app/ config/ db/ lib/ public/ report/ script/ spec/ vendor/fonts vendor/plugins/ vendor/cache/"
      excludes = "*.sample"

      package_name = "#{packprefix}_pack_staging_#{Time.now.strftime('%Y%m%d%H%M%S')}.tar.bz2"
      packagefile = "#{package_dir}#{package_name}"

      packing
    end
  end
end
