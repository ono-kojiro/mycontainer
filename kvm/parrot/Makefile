NAME = Parrot

all : help

help :
	@echo "usage: make TARGET"
	@echo ""
	@echo "target:"
	@echo "  dump             dump VM configuration"
	@echo "  patch            apply patch to VM configuration"
	@echo "  apply            apply new configuration" 

dump :
	virsh dumpxml $(NAME) > $(NAME).xml

patch :
	patch -p0 -i disable_secure_boot.patch

apply :
	virsh define $(NAME).xml


