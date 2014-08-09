# encoding: utf-8
namespace :enju do
  namespace :fixtures do
    desc 'Load CSV fixtures'
    task :csvload => :environment do
      require 'csv'
      Dir.glob("#{Rails.root}/db/fixtures/*.csv").sort.each do |file|
        puts "file load start. filename=#{file}"
        model_name = File.basename(file, '.*').gsub(/^\d+_/, '').classify
        eval(model_name).destroy_all
        tempfile = Tempfile.new("#{model_name.underscore}_fixture")
        open(file){|f|
          f.each{|line|
            tempfile.puts(NKF.nkf('-w -Lu', line))
          }   
        }   
        tempfile.close

        rows = CSV.open(tempfile, :col_sep => ",")
        header = rows.first
        rows.each_with_index do |row, index|
          record = eval(model_name).try(:new)
          row.each_with_index do |cell, j|
            if cell =~ /^#\{/
              record[header[j]] = eval('"' + cell.to_s + '"') if cell
            else
              record[header[j]] = cell.to_s if cell
            end
          end
          begin
	    record.save!
	  rescue => ex
            puts ex
	    puts "error index=#{index}"
	    pp record
	  end
        end                    
      end 
      puts "finished."
    end
  end
end
