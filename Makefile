.PHONY: dev versions bootstrap

dev:
	nix develop ~/dotfiles/dev-env

versions:
	go version
	rustc --version
	zig version
	node -v
	python3 --version
	odin version

bootstrap:
	./bootstrap.sh

