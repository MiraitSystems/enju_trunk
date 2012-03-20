cd $WORKSPACE
bundle config build.pg --with-pg-dir=/usr/local/pgsql/
bundle install
cd $WORKSPACE
./script/enju_setup pgsql
rake db:drop RAILS_ENV=test
rake db:create RAILS_ENV=test
rake db:migrate RAILS_ENV=test
rake sunspot:solr:stop RAILS_ENV=test
rake sunspot:solr:start RAILS_ENV=test
rake db:seed RAILS_ENV=test
bundle exec /usr/local/bin/rspec spec/

