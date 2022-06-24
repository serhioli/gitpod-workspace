.PHONY: build run

build:
	docker build -t dev .

run: build
	docker run --rm -it dev bash
