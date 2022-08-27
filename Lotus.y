%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h> 

/*==================Bison=======================*/
int yylex();
void yyerror(const char *s);

/*==================Global======================*/
char rem = '%';
char str[] = "\0";
char *main_name;
static int lables;

/*==================Memory======================*/
char *name[1024];
int value[1024];
int num = 0;

/*==================Register====================*/
bool reg[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int gerReg(){	
	for(int i = 0; i <= 9; i++){
		if(reg[i] == 0){
			reg[i] = 1;
			return i;
		}
	}
}
void putReg(int t){	
	reg[t] = 0;
}

/*===================Label======================*/
int newLable(){
	return ++lables;
}

%}

// Symbols.
%union
{
	struct val_node {
		int val;
		int treg;
	} vn;
	
	struct sval_node {
		char *sval;
		int treg;
	} s;
	
	struct bool_node {
		bool be_val;
		int lable_1;
		int lable_2;
		int lable_3;
	} bn;
	
	int lval;
	char *sval;
	bool b;
};

/* declare tokens */
%token <s>IDENTIFIER <lval>INTEGER	
%token <bn>IF <bn>ELSE EXIT INT <bn>WHILE WRITE READ	/* keyword */
%token EQUAL NOTEQUAL LESSEQUAL MOREEQUAL AND OR	/* Operator */
%token LESS MORE ADD SUB MUL DIV REM NOT ASSIGN TAIL COMMA OB CB OP CP	/* Operator */
%start program

%type<vn> arith_primary arith_factor arith_term arith_expression
%type<bn> bool_primary bool_factor bool_term bool_expression
%type<bn> if_statement subroutine

%%

program: IDENTIFIER  { main_name = $1.sval; } OP CP function_body 
	;
	
function_body: OB { printf("	.data \n"); }  variable_declarations { printf("\n	.text \n"); printf("%s:\n", main_name); } statements CB { }
	;
	
variable_declarations:	{  }
	| variable_declarations variable_declaration	{ }
	;
	
variable_declaration: INT IDENTIFIER TAIL	{ printf("%s:	.word 0\n",$2.sval); name[num] = $2.sval; num++; }
	;
	
statements: 	{  }
	| statements statement	{  }
	;
	
statement: assignment_statement 	{  }
	| compound_statement 	{  }
	| if_statement 	{  }
	| while_statement 	{  }
	| exit_statement 	{  }
	| read_statement 	{  }
	| write_statement	{  }
	;
	
assignment_statement: IDENTIFIER ASSIGN arith_expression TAIL	
			{ strcpy(str, $1.sval);
			  for(int i = 0; i < num; i++){
			  	if( !strcmp(name[i], str ) ){
			  		value[i] = $3.val;
			  		//printf("%s = %d\n" ,$1.sval, $3.val);
			  		break;
			  	}
			 }
			 $1.treg = gerReg();
			 //printf("	li	$t%d, %d\n", $3.treg, $3.val);
			 printf("	la	$t%d, %s\n", $1.treg, $1.sval);
			 printf("	sw	$t%d, 0($t%d)\n",$3.treg, $1.treg);
			 putReg($3.treg);
			 putReg($1.treg);
			}
	;
		
compound_statement: OB statements CB	{  }
	;
		
if_statement: subroutine statement	{ 
				   printf("L%d:	#end if\n",$1.lable_1);
				       	 }
	| subroutine statement 
			   ELSE {   
			   	   $1.lable_2 = newLable();	
			   	   printf("	b	L%d\n",$1.lable_2); 					
				   printf("L%d:	#else\n", $1.lable_1);
				   } 
		      statement {     	
				   printf("L%d:	#end if\n",$1.lable_2);
				   }
	;
	
subroutine: IF OP bool_expression CP { printf("L%d:	#then\n",$3.lable_1); } { $$.lable_1 = $3.lable_2;} 
	;

while_statement:WHILE 
		{ $1.lable_1 = newLable(); }
		/*{ printf("L%d L%d\n",$1.lable_1 ,$1.lable_2); }*/
		{ printf("L%d:	#while\n",$1.lable_1); } 
		
		OP bool_expression 
		{ printf("L%d:	#body\n", $5.lable_1); } 
		
		CP statement	
		{ printf("	b	L%d\n",$1.lable_1); 
		  printf("L%d:	#end while\n",$5.lable_2);
		  }
	;
		
		
/*===============System Call===============*/
exit_statement: EXIT TAIL	{ printf("	li	$v0, 10\n");
				  printf("	syscall\n"); }  
	;
		
read_statement:READ IDENTIFIER TAIL	{ printf("	li	$v0, 5\n");
					  printf("	syscall\n");
				 	  printf("	la	$t%d, %s\n",$2.treg, $2.sval);
				 	  printf("	sw	$v0, 0($t%d)\n",$2.treg);
				 	    }
	;
	
write_statement:WRITE arith_expression TAIL	{ printf("	move	$a0, $t%d\n",$2.treg);
						  printf("	li	$v0, 1\n");
						  printf("	syscall\n"); 
						  putReg($2.treg);
						  }
	;
/*=========================================*/
	
	
bool_expression: bool_term { $$.lable_1 = $1.lable_1;
			      $$.lable_2 = $1.lable_2; }
	|bool_expression OR bool_term	{ /*........*/ }
	;
	
bool_term: bool_factor		{ $$.lable_1 = $1.lable_1;
				  $$.lable_2 = $1.lable_2; }
	|bool_term AND bool_factor	{ /*........*/ }
	;
	
bool_factor: bool_primary	{ $$.lable_1 = $1.lable_1;
				  $$.lable_2 = $1.lable_2;} 
	|NOT bool_primary	{ /*........*/ }
	;
	
bool_primary: arith_expression EQUAL arith_expression { 
							  $$.lable_1 = newLable();
							  $$.lable_2 = newLable();
							  printf("	beq	$t%d, $t%d, L%d\n",$1.treg, $3.treg, $$.lable_1); 
							  printf("	b	L%d\n",$$.lable_2);
							  putReg($1.treg);
			 				  putReg($3.treg);  }
	|arith_expression NOTEQUAL arith_expression	{ 
							  $$.lable_1 = newLable();
							  $$.lable_2 = newLable();
							  printf("	bne	$t%d, $t%d, L%d\n",$1.treg, $3.treg, $$.lable_1); 
							  printf("	b	L%d\n",$$.lable_2);
							  putReg($1.treg);
			 				  putReg($3.treg); }
	|arith_expression MORE arith_expression	{ /*if($1.val > $3.val){ $$.be_val = 1; } else { $$.be_val = 0; }*/
							  $$.lable_1 = newLable();
							  $$.lable_2 = newLable();
							  printf("	bgt	$t%d, $t%d, L%d\n",$1.treg, $3.treg, $$.lable_1); 
							  printf("	b	L%d\n",$$.lable_2);
							  putReg($1.treg);
			 				  putReg($3.treg); }
							 
	|arith_expression MOREEQUAL arith_expression	{ 
							  $$.lable_1 = newLable();
							  $$.lable_2 = newLable();
							  printf("	bge	$t%d, $t%d, L%d\n",$1.treg, $3.treg, $$.lable_1); 
							  printf("	b	L%d\n",$$.lable_2);
							  putReg($1.treg);
			 				  putReg($3.treg); }
	|arith_expression LESS arith_expression	{ /*if($1.val < $3.val){ $$.be_val = 1; } else { $$.be_val = 0; }*/
							  $$.lable_1 = newLable();
							  $$.lable_2 = newLable();
							  printf("	blt	$t%d, $t%d, L%d\n",$1.treg, $3.treg, $$.lable_1); 
							  printf("	b	L%d\n",$$.lable_2);
							  putReg($1.treg);
			 				  putReg($3.treg); }
	|arith_expression LESSEQUAL arith_expression	{ 
							  $$.lable_1 = newLable();
							  $$.lable_2 = newLable();
							  printf("	ble	$t%d, $t%d, L%d\n",$1.treg, $3.treg, $$.lable_1); 
							  printf("	b	L%d\n",$$.lable_2);
							  putReg($1.treg);
			 				  putReg($3.treg); }
	;
	
arith_expression: arith_term	{ $$.val = $1.val; $$.treg = $1.treg; }
	|arith_expression ADD arith_term	{ printf("	add	$t%d, $t%d, $t%d\n",$1.treg ,$1.treg ,$3.treg );
						  $$.val = $1.val + $3.val; $$.treg = $1.treg; /*printf("%d\n", $$.val);*/
						  putReg($3.treg); }
	|arith_expression SUB arith_term	{ printf("	sub	$t%d, $t%d, $t%d\n",$1.treg ,$1.treg ,$3.treg );
						  $$.val = $1.val - $3.val; $$.treg = $1.treg; /*printf("%d\n", $$.val);*/
						  putReg($3.treg); }
	;
		
arith_term:arith_factor	{ $$.val = $1.val; $$.treg = $1.treg; }
	|arith_term MUL arith_factor	{ $$.val = $1.val * $3.val; printf("	mul	$t%d, $t%d, $t%d\n", $1.treg, $1.treg, $3.treg);
					  //printf("%d * %d = %d\n", $1.val, $3.val, $$.val);
					  $$.treg = $1.treg;
					  putReg($3.treg);	}
	|arith_term DIV arith_factor	{ $$.val = $1.val / $3.val; printf("	div	$t%d, $t%d, $t%d\n", $1.treg, $1.treg, $3.treg);
					  //printf("%d / %d = %d\n", $1.val, $3.val, $$.val);
					  $$.treg = $1.treg;
					  putReg($3.treg); }
	|arith_term REM arith_factor	{ $$.val = $1.val % $3.val; printf("	rem	$t%d, $t%d, $t%d\n", $1.treg, $1.treg, $3.treg);
					  //printf("%d %c %d = %d\n", $1.val, rem, $3.val, $$.val);
					  $$.treg = $1.treg;
					  putReg($3.treg); }
	;
	
arith_factor: arith_primary	{ $$.val = $1.val; $$.treg = $1.treg; }
	|SUB arith_primary	{ $$.val = $2.val * (-1); $$.treg = $2.treg;
				  printf("	neg	$t%d, $t%d\n", $2.treg, $2.treg);}
	;
	
arith_primary: INTEGER	{ $$.val = $1; 
			  $$.treg = gerReg();
		          printf("	li	$t%d, %d\n", $$.treg, $1);
		          
		         }		          
	|IDENTIFIER	{ $$.treg = gerReg();
			  strcpy(str, $1.sval);
			  for(int i = 0; i < num; i++){
				if( !strcmp(name[i], str ) ){
			  		$$.val = value[i];
			  		//printf("%s = %d\n" ,str, value[i]);
			  		break;
			  	}	
			  }
			  printf("	la	$t%d, %s\n",$$.treg ,$1.sval);
			  printf("	lw	$t%d, 0($t%d)\n",$$.treg ,$$.treg);
			}
	|OP arith_expression CP	{ $$.val = $2.val; $$.treg = $2.treg; }
	;
	
%%
/*String emit()
{

}*/
int main(int argc, char **argv)
{
	yyparse();
}

void yyerror(const char *s)
{
	extern int yylineno;
	fprintf(stderr, "%s:line %d\n",s ,yylineno );
}

