namespace :enju_trunk do
  desc 'copy tools from enju_trunk.'
  task :copy_tools do
    #copy_file file, file
    copy_src = "#{EnjuTrunk::Engine.root.to_s}/script/tools"
    copy_dest = "#{Rails.root.to_s}/script/tools"
   
    puts "copy_src=#{copy_src} copy_dest=#{copy_dest}"
    FileUtils.copy_entry(copy_src, copy_dest)
    puts "done."

  end
end

