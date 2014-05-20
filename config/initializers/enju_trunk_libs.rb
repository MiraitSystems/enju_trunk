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

# theme
if defined?(EnjuTrunkTheme)
  begin
    Dir[EnjuTrunkTheme::Engine.root.to_s + EnjuTrunkTheme::class_evals_dir + "*.rb"].each { |file| require file }
  rescue => e
    puts e.message 
    # NO CUSTOM VALIDATOR
  end
end
