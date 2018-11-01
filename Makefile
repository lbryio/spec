index.html: index.md style.css
	# ./bin/gh-md-toc --insert index.md
	./bin/mmark-linux-amd64 -head head.html -html index.md > index.html