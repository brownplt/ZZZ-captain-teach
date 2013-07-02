all: setup dep pyret-editor-service

setup:
	raco link -n ct-scribble scribble

dep:
	git submodule init CodeMirror pyret-editor-backend ct-assignments
	git submodule update CodeMirror pyret-editor-backend ct-assignments

pyret-editor-service:
	cd pyret-editor-backend; make pyret

test:
	cd tests; \
	racket setup.rkt --whalesong-url http://localhost:8080; \
	echo Remember to start whalesong on port 8080; \
	echo See the tests at http://localhost:8000/tests/run.html; \
	python -m SimpleHTTPServer

editors:
	mkdir editors
	cd editors; \
	git init; \
	touch __blank; \
	git add .; \
	git commit -m "initial commit"
