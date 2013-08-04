#!/bin/bash

cd web/

rake db:setup RAILS_ENV=test

PIDFILE="../tests/casper-test-server.pid"

rails s -e test -p 4000 -P $PIDFILE &

PID=$!
echo "PID is $PID"

while [ ! -s $PIDFILE ]
  do
  printf "%10s \r" waiting...
done

cat $PIDFILE

casperjs ../tests/casper-tests.js

kill $PID

