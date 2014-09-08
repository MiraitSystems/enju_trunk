require 'thor'
class EnjuPackage
  attr_accessor :dir_prefix, :base_dir, :package_dir, :pack_prefix

  def initialize
    require 'thor'
    require 'thor/group'

    @dir_prefix = "customer"
    if ENV["ENJU_CUSTOMER_PREFIX"]
      @dir_prefix = ENV["ENJU_CUSTOMER_PREFIX"]
      Rails.logger.info "set prefix=#{dirprefix}"
    end

    @base_dir = ENV['HOME']

    @package_dir = File.join(@base_dir, @dir_prefix, "pack")
    @pack_prefix = "enju_production"
  end

  def pack(package_file, archives, excludes_file = "script/tools/exclude_init")
    sh "cd #{::Rails.root}; tar cjvf #{package_file} #{archives.join(' ')} -X #{excludes_file}"
  end

  def sh(args)
    system(args)
  end

  def self.generate_gitlastlog(current_dir = ::Rails.root)
    if FileTest::directory?(File.join(current_dir, ".git"))
      system("cd #{current_dir}; git log -1 > GitLastLog")
    else 
      return false
    end
    return true
  end

  def question_yes_or_no
    STDOUT.flush
    input = STDIN.gets.chomp
    case input.upcase
    when "Y"
      return true
    when "N"
      return false
    else
      puts "Please enter Y or N"
      get_input
    end
  end 

end
