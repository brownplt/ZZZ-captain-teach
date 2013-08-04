#!/bin/bash

cd web/

rake db:setup RAILS_ENV=test

rails s --daemon -e test -p 4000

casperjs ../tests/casper-tests.js

kill `cat ../web/tmp/pids/server.pid`

