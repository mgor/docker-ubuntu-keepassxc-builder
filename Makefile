NAME = mgor/ubuntu-keepassxc-builder
HOSTNAME = keepassxc-builder

.PHONY = all build run clean

USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

ifndef RELEASE
	RELEASE := $(shell lsb_release -cs)
endif

all: build clean run

build:
	docker pull mgor/docker-ubuntu-pkg-builder:$(RELEASE)
	sed -r 's|RELEASE|$(RELEASE)|' Dockerfile.template > Dockerfile
	docker build -t $(NAME) .
	rm Dockerfile

run:
	docker run --rm --name $(HOSTNAME) --hostname $(HOSTNAME) -v $(CURDIR)/packages:/usr/local/src --env USER_ID=$(USER_ID) --env GROUP_ID=$(GROUP_ID) -it $(NAME)

clean:
	rm -rf $(CURDIR)/packages/* Dockerfile
