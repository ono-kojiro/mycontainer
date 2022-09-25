IMAGE = simple
NAME = simple

all : hello image

help :
	@echo "make [TARGET]"
	@echo "target:"
	@echo "  build, image     build empty image"
	@echo "  create           create container"
	@echo "  start            start container"
	@echo "  attach           attach container"
	@echo "  stop             stop container"
	@echo "  run              create new container and run it"
	@echo "  rm               remove container"
	@echo "  rmi              remove image"

hello :
	gcc -o hello -static hello.c


build :
	docker build --tag $(IMAGE) .

image :
	$(MAKE) build

tag :
	docker tag $(IMAGE) 192.168.0.98:5000/$(IMAGE)

push :
	docker push 192.168.0.98:5000/$(IMAGE)

inspect :
	docker inspect $(NAME)

start :
	docker start $(NAME)

attach :
	@echo press Ctrl+P, Ctrl+Q to quit
	docker attach $(NAME)

stop :
	docker stop $(NAME)

rm :
	-docker rm $(NAME)

rmi :
	-docker rmi $(IMAGE)

clean :
	rm -f ./hello
	$(MAKE) rmi rm

