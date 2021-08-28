TESTSCRIPTS = $(sort $(wildcard *.t))
TESTLOGS    = $(TESTSCRIPTS:.t=.log)

all : log

log : $(TESTLOGS)

%.log : %.t
	prove -v $< 2>&1 | tee $@

% :
	prove -v $@.t 2>&1 | tee $@.log

clean :
	rm -f $(TESTLOGS)

.PHONY : \
	all clean test log

