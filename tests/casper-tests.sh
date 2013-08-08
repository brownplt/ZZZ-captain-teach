#!/bin/bash --login

cd web/

echo "Starting up rails server, setting up database"

rake db:setup RAILS_ENV=test >&/dev/null

PIDFILE="../tests/casper-test-server.pid"

rails s -e test -p 4000 -P $PIDFILE >&/dev/null &

PID=$!
echo "PID is $PID"

while [ ! -s $PIDFILE ]
  do
  printf "%10s \r" waiting...
done

#cat $PIDFILE
echo "running scripts"

for a in `ls ../tests/casper/*.js`
do
    echo $a;
    casperjs $a;
done;

#casperjs ../tests/casper-tests.js

kill $PID
