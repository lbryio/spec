index.html: index.md head.html
	./bin/mmark-linux-amd64 -head head.html -html index.md > index.html
	./bin/toc.sh index.html index.md