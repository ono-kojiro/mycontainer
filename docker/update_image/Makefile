TESTSCRIPTS = $(sort $(wildcard 0*.t))
TESTLOGS    = $(TESTSCRIPTS:.t=.log)

all : log

log : $(TESTLOGS)

%.log : %.t
	prove $< 2>&1 | tee $@

init :
	prove -v 00-deploy_registry.t

clean :
	prove -v 99-remove_registry.t

.PHONY : \
	all clean test log \
	test-base test-adv


