#!/usr/bin/make -f

.PHONY: clean build

all: clean files/fswebcam build

clean:
	rm -rf output-qemu

build: clean
	packer build -var-file=config.json -on-error=ask arch.json

files/fswebcam:
	docker run -it -v $$PWD/files:/root/files archlinux:20200705 /root/files/fswebcam.sh
