namespace :enju do
  namespace :install do
    namespace :migrations do
      MAIN_PATH = Rails.root.to_s 

      def import_migrations(name)
        engine_path = eval("#{name}::Engine").root.to_s rescue nil 
        puts "directly import migration files from #{engine_path} to #{MAIN_PATH}"
        system "rsync -ruv #{engine_path}/db/migrate #{MAIN_PATH}/db/" if engine_path
      end

      desc 'Directly import all migrations'
      task :all => :environment do
        %w(
          EnjuTrunk 
          EnjuEvent 
          EnjuManifestationViewer
          JppCustomercodeTransfer 
        ).each do |name|
          import_migrations(name)
        end
      end

      desc 'Directly import enju_trunk migrations'
      task :enju_trunk => :environment do
        import_migrations("EnjuTrunk")
      end

      desc 'Directly import enju_event migrations'
      task :enju_event => :environment do
        import_migrations("EnjuEvent")
      end

      desc 'Directly import enju_manifestation_viewer migrations'
      task :enju_manifestation_viwer => :environment do
        import_migrations("EnjuManifestationViewer")
      end

      desc 'Directly import jpp_customercode_transfer migrations'
      task :jpp_customercode_transfer => :environment do
        import_migrations("JppCustomercodeTransfer")
      end
    end
  end
end
