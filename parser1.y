%{
#include <stdio.h>

void yyerror(const char *s);
int yylex(void);
%}

%token BEGIN HELLO THANKS END

%%

program:
    program statement
    | /* vazio */
    ;

statement:
    BEGIN   { printf("Started\n"); }
    | HELLO   { printf("Hello yourself!\n"); }
    | THANKS  { printf("You are welcome\n"); }
    | END     { printf("Stopped\n"); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int main(void) {
    return yyparse();
}
