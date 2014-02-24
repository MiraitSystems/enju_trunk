namespace :enju do
  namespace :resource_import do
    desc 'Import resources'
    task :start => :environment do
      ResourceImportFile.import
    end
  end
  namespace :agent_import do
    desc 'Import agents'
    task :start => :environment do
      AgentImportFile.import
    end
  end
  namespace :event_import do
    desc 'Import events'
    task :start => :environment do
      EventImportFile.import
    end
  end
end
