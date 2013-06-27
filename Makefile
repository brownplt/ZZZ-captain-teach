scribble:
	raco link -n ct-scribble scribble
test:
	cd tests; \
	racket setup.rkt --whalesong-url http://localhost:8080; \
	echo Remember to start whalesong on port 8080; \
	echo See the tests at http://localhost:8000/tests/run.html; \
	python -m SimpleHTTPServer
