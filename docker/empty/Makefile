IMAGE = empty
NAME = empty

all : image

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

build :
	docker build --tag $(IMAGE) .

image :
	$(MAKE) build
	
create :
	docker create \
		-it \
		--name $(NAME) \
		--hostname $(NAME) \
		--mount type=bind,source=/bin,target=/bin,readonly \
		--mount type=bind,source=/usr,target=/usr,readonly \
		--mount type=bind,source=/lib,target=/lib,readonly \
		--mount type=bind,source=/lib32,target=/lib32,readonly \
		--mount type=bind,source=/lib64,target=/lib64,readonly \
		--mount type=bind,source=/libx32,target=/libx32,readonly \
		--mount type=bind,source=/etc,target=/etc,readonly \
		$(IMAGE)

inspect :
	docker inspect ${NAME}

start :
	docker start ${NAME}

attach :
	@echo press Ctrl+P, Ctrl+Q to quit
	docker attach ${NAME}

stop :
	docker stop ${NAME}

rm :
	-docker rm $(NAME)

rmi :
	-docker rmi $(IMAGE)

clean :
	$(MAKE) rmi rm

