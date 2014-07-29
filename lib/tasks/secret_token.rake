namespace :enju_trunk do
  desc 'Generates a secret token for the application.'
  task :generate_secret_token do
	  path = File.join(Rails.root, 'config', 'initializers', 'secret_token.rb')
	  secret = SecureRandom.hex(40)
	  File.open(path, 'w') do |f|
		  f.write <<"EOF"
    #{Rails.application.class.parent_name}::Application.config.secret_token = '#{secret}'
EOF
		end
  end
end

