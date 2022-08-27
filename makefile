all: clean lotus

lotus: Lotus.lex Lotus.y
	bison -d Lotus.y
	flex Lotus.lex
	gcc -o lotus Lotus.tab.c lex.yy.c -lfl

clean: 
	rm -f lotus Lotus.tab.c Lotus.tab.h lex.yy.c
