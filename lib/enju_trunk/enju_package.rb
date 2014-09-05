class EnjuPackage
  def pack(root_dir, package_file, archives, excludes_file)
    sh "cd #{root_dir}; tar cjvf #{package_file} #{archives} --exclude #{excludes_file}"
  end
end
