%{
#include "stdio.h"
#include "stdlib.h"
#include <stdbool.h> 
#include "Lotus.tab.h"
%}

/*Regular*/
%option yylineno
letter	[A-Za-z]
IDENTIFIER  {letter}({letter}|{digit})*
digit	[0-9]
INTEGER   {digit}+(\.{digit}+)?(E[+-]?{digit}+)?

%%
"if"		{return IF; }
"else"		{return ELSE;}
"exit"		{return EXIT;}
"int"		{return INT;}
"read"		{return READ;}
"while"	{return WHILE;}
"write"	{return WRITE;}

"<" { return LESS; }
">" { return MORE; }
"+" { return ADD; }
"-" { return SUB; }
"*" { return MUL; }
"/" { return DIV; }
"%" { return REM; }
"!" { return NOT; }
"=" { return ASSIGN; }
";" { return TAIL; }
"," { return COMMA; }
"{" { return OB; }
"}" { return CB; }
"(" { return OP; }
")" { return CP; }

"==" { return EQUAL; }
"!=" { return NOTEQUAL; }
">=" { return MOREEQUAL; }
"<=" { return LESSEQUAL; }
"&&" { return AND; }
"||" { return OR; }

{IDENTIFIER} {
			yylval.sval = malloc(strlen(yytext));
			strncpy(yylval.sval, yytext, strlen(yytext));
			return(IDENTIFIER);
}
{INTEGER} { yylval.lval = atoi(yytext); return INTEGER; }

"//".* { /* ignore */ }
[ \t] { /* ignore */ }
\n { /* ignore */ }

. { printf("Lexical error: line %d: unknown character %s\n", yylineno, yytext); }
%%

