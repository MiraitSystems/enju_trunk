namespace :enju do
  namespace :nacsis_import do
    desc 'Import from NACSIS'
    task :start => :environment do
      ncids = {}
      files = []

      if ENV['FILE']
        files = [ENV['FILE']]
      else
        files = Dir.glob(UserFile.path_format%['*', 'resource_import_nacsisfile', '*', '*'])
      end

      files.each do |file|
        IO.foreach(file) do |line|
          id = line.strip
          ncids[id] = true if id.present?
        end
      end

      Manifestation.
        where(nacsis_identifier: ncids.keys).
        select(:nacsis_identifier).each do |record|
          ncids.delete(record.nacsis_identifier)
        end

      SeriesStatement.
        where(nacsis_series_statementid: ncids.keys).
        select(:nacsis_series_statementid).each do |record|
          ncids.delete(record.nacsis_series_statementid)
        end

      created_m = created_s = failed = 0
      NacsisCat.batch_create_from_ncid(ncids.keys) do |m|
        if m.persisted?
          case m.class.name
          when Manifestation.name
            created_m += 1
          when SeriesStatement.name
            created_s += 1
          end
        else
          failed += 1
        end
      end

      if (created_m + created_s) > 0
        Sunspot.commit
      end

      puts "#{Manifestation.name} imported #{created_m} records"
      puts "#{SeriesStatement.name} imported #{created_s} records"
      puts "#{failed} failures"
    end
  end
end
