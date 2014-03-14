Dir[Rails.root.to_s + "/lib/enju_trunk/**/base.rb"].each do 
  |file|
  require file
end
Dir[Rails.root.to_s + "/lib/enju_trunk/**/*.rb"].each do 
  |file|
  require file
end

# nacsis
begin
  NACSIS_CLIENT_CONFIG = YAML.load_file("#{Rails.root}/config/nacsis_client.yml")
rescue Errno::ENOENT
  # skip.
end

# custom 
if defined?(EnjuCustomize)
  begin
    #require EnjuCustomize.render_dir + '/custom_validator'
    Dir[EnjuCustomize.root.to_s + EnjuCustomize.class_evals_dir + "*.rb"].each { |file| require file }
  rescue
    # NO CUSTOM VALIDATOR
  end
end
