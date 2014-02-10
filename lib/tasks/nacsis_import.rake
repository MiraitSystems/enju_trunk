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

      created = failed = 0
      types = ManifestationType.book.all
      Manifestation.batch_create_from_ncid(ncids.keys, book_types: types) do |m|
        if m.persisted?
          created += 1
        else
          failed += 1
        end
      end

      if created > 0
        Sunspot.commit
      end

      puts "imported #{created} records, #{failed} failures"
    end
  end
end
