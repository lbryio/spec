index.html: index.md style.css
	./bin/gh-md-toc --insert index.md
	./bin/mmark-linux-amd64 -css style.css -html index.md > index.html