all: rails keys

rails:
	rake db:setup
	guard

keys: config/test.key config/development.key config/production.key

config/test.key:
	config/create_key.rb config/test.key

config/development.key:
	config/create_key.rb config/development.key

config/production.key:
	config/create_key.rb config/production.key

