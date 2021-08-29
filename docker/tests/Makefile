BASESCRIPTS = $(sort $(wildcard 0*.t))
ADVSCRIPTS  = $(sort $(wildcard 1*.t))

TESTSCRIPTS = $(BASESCRIPTS) $(ADVSCRIPTS)
TESTLOGS    = $(TESTSCRIPTS:.t=.log)

all : log

test-base : $(sort $(BASESCRIPTS:.t=.log))

test-adv  : $(sort $(ADVSCRIPTS:.t=.log))

log : $(TESTLOGS)

%.log : %.t
	prove -v $< 2>&1 | tee $@

% :
	prove -v $@.t 2>&1 | tee $@.log

clean :
	rm -f $(TESTLOGS)

.PHONY : \
	all clean test log \
	test-base test-adv


