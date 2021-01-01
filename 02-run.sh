#!/bin/sh

docker run \
	--name mycontainer \
	-d \
	-p 10022:22 \
	-p 10080:80 \
	--privileged \
	-v /home:/home \
	myimage

