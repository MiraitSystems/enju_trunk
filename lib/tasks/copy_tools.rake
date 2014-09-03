namespace :enju_trunk do
  desc 'copy tools from enju_trunk.'
  task :copy_tools do
    #copy_file file, file
    copy_src = "#{EnjuTrunk::Engine.root.to_s}/script/tools"
    copy_dest = "#{Rails.root.to_s}/script"

    puts "copy tools. copy_src=#{copy_src} copy_dest=#{copy_dest}"
    system "rsync -ruv #{copy_src} #{copy_dest}"
    puts "done."

  end

  desc 'copy fixtures from enju_trunk.'
  task :copy_fixtures do
    #copy_file file, file
    copy_src = "#{EnjuTrunk::Engine.root.to_s}/lib/generators/enju_trunk/install/templates/db/fixtures"
    copy_dest = "#{Rails.root.to_s}/db/fixtures/enju_trunk"

    puts "copy fixtures. copy_src=#{copy_src} copy_dest=#{copy_dest}"
    system "rsync -ruv #{copy_src} #{copy_dest}"
    puts "done."

  end

  desc 'update fixtures and migration file , tools'
  task :update do
    Rake::Task['enju_trunk:copy_tools'].execute
    Rake::Task['enju_trunk:copy_fixtures'].execute
    Rake::Task['enju:install:migrations:all'].execute
  end

  desc 'update solr_jar path (config/sunspot.yml)'
  task :update_solr_jar_path do
    main_path = Rails.root.to_s
    sunspot_config_file = File.join(main_path, "/config/sunspot.yml")
    solr_jar_path = ["example","/start.jar"]
    solr_install_path = ["vendor","apache-solr-3.6.2"]
    solr_start_path = File.join(main_path, solr_install_path, solr_jar_path)

    yml = YAML.load_file(sunspot_config_file)
    yml["production"]["solr"]["solr_jar"] = solr_start_path
    yml["development"]["solr"]["solr_jar"] = solr_start_path
    yml["test"]["solr"]["solr_jar"] = solr_start_path

    File.open(sunspot_config_file, 'w+') {|f| f.write(yml.to_yaml) }

  end

end

