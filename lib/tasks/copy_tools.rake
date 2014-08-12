namespace :enju_trunk do
  desc 'copy tools from enju_trunk.'
  task :copy_tools do
    #copy_file file, file
    copy_src = "#{EnjuTrunk::Engine.root.to_s}/script/tools"
    copy_dest = "#{Rails.root.to_s}/script/tools"

    puts "copy tools. copy_src=#{copy_src} copy_dest=#{copy_dest}"
    FileUtils.copy_entry(copy_src, copy_dest)
    puts "done."

  end

  desc 'copy fixtures from enju_trunk.'
  task :copy_fixtures do
    #copy_file file, file
    copy_src = "#{EnjuTrunk::Engine.root.to_s}/lib/generators/enju_trunk/install/templates/db/fixtures"
    copy_dest = "#{Rails.root.to_s}/db/fixtures/enju_trunk"

    puts "copy fixtures. copy_src=#{copy_src} copy_dest=#{copy_dest}"
    FileUtils.copy_entry(copy_src, copy_dest)
    puts "done."

  end

  desc 'update fixtures and migration file , tools'
  task :update do
    Rake::Task['enju_trunk:copy_tools'].execute
    Rake::Task['enju_trunk:copy_fixtures'].execute
    Rake::Task['enju:install:migrations:all'].execute
  end
end

