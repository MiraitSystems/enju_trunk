class EnjuPackage

  def pack(root_dir, package_file, archives, excludes_file)
    system("cd #{root_dir}; tar cjvf #{package_file} #{archives} --exclude #{excludes_file}")
  end

  def self.generate_gitlastlog(current_dir = ::Rails.root)
    if FileTest::directory?(File.join(current_dir, ".git"))
      system("cd #{current_dir}; git log -1 > GitLastLog")
    else 
      return false
    end
    return true
  end
end
