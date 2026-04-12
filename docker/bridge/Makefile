all : help

help :
	@echo "usage: make TARGET"
	@echo ""
	@echo "  target:"
	@echo "  - bridge"
	@echo "  - network"
	@echo ""
	@echo "  - rmb"
	@echo "  - rmn"

full : bridge network

bridge:
	./build.py -c config.yml create_bridge

br : bridge

rmb:
	./build.py -c config.yml remove_bridge

network:
	./build.py -c config.yml create_network

nw : network

rmn:
	./build.py -c config.yml remove_network

ls : lsb lsn

lsb:
	./build.py -c config.yml list_bridges

lsn:
	./build.py -c config.yml list_networks

inspect:
	./build.py -c config.yml inspect

destroy :
	$(MAKE) rmn rmb

