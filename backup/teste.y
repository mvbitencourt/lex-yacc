%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

typedef struct Scope {
    struct Scope *next;
} Scope;

Scope *scope_stack = NULL;

void push_scope() {
    Scope *new_scope = (Scope *)malloc(sizeof(Scope));
    new_scope->next = scope_stack;
    scope_stack = new_scope;
    printf("Escopo criado\n");
}

void pop_scope() {
    if (scope_stack != NULL) {
        Scope *old_scope = scope_stack;
        scope_stack = scope_stack->next;
        free(old_scope);
        printf("Escopo removido\n");
    } else {
        printf("Erro: Tentativa de remover escopo inexistente\n");
    }
}
%}

%union {
    int ival;
    char *sval;
}

%token <sval> BLOCO_INICIO BLOCO_FIM IDENTIFICADOR CADEIA
%token <ival> NUMERO
%token TIPO_NUMERO TIPO_CADEIA PRINT

%%

inicio:
    inicio programa
    | /* vazio */
    ;

programa:
    bloco
    | /* vazio */
    ;

bloco:
    BLOCO_INICIO escopo BLOCO_FIM
    ;

escopo: 
    escopo linha
    | escopo bloco
    | /* vazio */
    ;

linha:
    linha_declaracao   
    | linha_atribuicao 
    | linha_print      
    | /* vazio */
    ;

linha_declaracao:
    TIPO_NUMERO IDENTIFICADOR ';'              {printf("linha_declaracao");}
    | TIPO_NUMERO IDENTIFICADOR '=' NUMERO ';' {printf("linha_declaracao");}
    | TIPO_CADEIA IDENTIFICADOR '=' CADEIA ';' {printf("linha_declaracao");}
    ;

linha_atribuicao:
    IDENTIFICADOR '=' NUMERO ';'          {printf("linha_atribuicao");}
    | IDENTIFICADOR '=' CADEIA ';'        {printf("linha_atribuicao");}
    | IDENTIFICADOR '=' IDENTIFICADOR ';' {printf("linha_atribuicao");}
    ;

linha_print:
    PRINT IDENTIFICADOR {printf("linha_print");}
    ;

=============================================================================

program:
    program statement
    | /* vazio */
    ;

statement:
    BLOCO_INICIO { printf("Token: BLOCO_INICIO\n"); }
    | BLOCO_FIM { printf("Token: BLOCO_FIM\n"); }
    | TIPO_NUMERO { printf("Token: TIPO_NUMERO\n"); }
    | TIPO_CADEIA { printf("Token: TIPO_CADEIA\n"); }
    | PRINT { printf("Token: PRINT\n"); }
    | IDENTIFICADOR { printf("Token: IDENTIFICADOR (%s)\n", $1); free($1); }
    | NUMERO { printf("Token: NUMERO (%d)\n", $1); }
    | CADEIA { printf("Token: CADEIA (%s)\n", $1); free($1); }
    | '=' { printf("Token: =\n"); }
    | ';' { printf("Token: ;\n"); }
    | ',' { printf("Token: ,\n"); }
    | '+' { printf("Token: +\n"); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int main(void) {
    return yyparse();
}