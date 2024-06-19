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

programa:
    programa linha
    | /* vazio */
    ;

linha:
    | linha_inicio_bloco
    | linha_fim_bloco
    | linha_declaracao
    | linha_atribuicao
    | linha_print
    | /* vazio */
    ;

linha_inicio_bloco:
    BLOCO_INICIO {printf("linha_inicio_bloco\n");}
    ;

linha_fim_bloco:
    BLOCO_FIM {printf("linha_fim_bloco\n");}
    ;

linha_declaracao:
    TIPO_NUMERO IDENTIFICADOR ';' {printf("linha_declaracao\n");}
    | TIPO_CADEIA decl_cadeia_list ';' {printf("linha_declaracao\n");}
    | TIPO_NUMERO decl_numero_list ';' {printf("linha_declaracao\n");}    
    ;
    decl_cadeia_list:
        decl_cadeia
        | decl_cadeia_list ',' decl_cadeia
        ;

    decl_cadeia:
        IDENTIFICADOR '=' CADEIA
        | IDENTIFICADOR
        ;
    decl_numero_list:
        decl_numero
        | decl_numero_list ',' decl_numero
        ;
    decl_numero:
        IDENTIFICADOR '=' numero_expr
        | IDENTIFICADOR
        ;
    numero_expr:
        NUMERO
        | numero_expr '+' NUMERO
        ;

linha_atribuicao:
    IDENTIFICADOR '=' NUMERO ';'          {printf("linha_atribuicao\n");}
    | IDENTIFICADOR '=' CADEIA ';'        {printf("linha_atribuicao\n");}
    | IDENTIFICADOR '=' IDENTIFICADOR ';' {printf("linha_atribuicao\n");}
    ;

linha_print:
    PRINT IDENTIFICADOR ';' {printf("linha_print\n");}
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int main(void) {
    return yyparse();
}