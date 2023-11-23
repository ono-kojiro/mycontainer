SRCS = mysnmpwalk.c
OBJS = $(SRCS:.c=.o)
PROG = mysnmpwalk

MIBDIRS = $(HOME)/.snmp/mibs
MIBS    = ALL

all : obj prog

obj : $(OBJS)

prog : $(PROG)

%.o : %.c
	gcc -c -o $@ $<

$(PROG) : $(OBJS)
	gcc -o $@ $(OBJS) -lsnmp

sync :
	rsync -avz opnsense:/usr/local/share/snmp/mibs $(HOME)/.snmp/

test :
	./mysnmpwalk  -M $(MIBDIRS) -v 2c -c public 192.168.10.1 .
	snmptranslate -M $(MIBDIRS) 1.3.6.1.4.1

test2 :
	snmptranslate 1.3.6.1.4.1

clean :
	rm -f $(OBJS) $(PROG)

.PHONY : \
	all clean test obj prog

