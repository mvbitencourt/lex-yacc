%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

typedef struct Escopo {
    struct Escopo *proximo;
} Escopo;

Escopo *pilha_de_escopos = NULL;

void empilhar_escopo() {
    Escopo *novo_escopo = (Escopo *)malloc(sizeof(Escopo));
    novo_escopo->proximo = pilha_de_escopos;
    pilha_de_escopos = novo_escopo;
    printf("Escopo criado\n");
}

void desempilhar_escopo() {
    if (pilha_de_escopos != NULL) {
        Escopo *escopo_antigo = pilha_de_escopos;
        pilha_de_escopos = pilha_de_escopos->proximo;
        free(escopo_antigo);
        printf("Escopo removido\n");
    } else {
        printf("Erro: Tentativa de remover escopo inexistente\n");
    }
}

void inicializar_pilha_de_escopos() {
    pilha_de_escopos = NULL;
    printf("Pilha de escopos inicializada\n");
}

void imprimir_pilha() {
    printf("Pilha = [");
    Escopo *atual = pilha_de_escopos;
    while (atual != NULL) {
        printf("[]");
        if (atual->proximo != NULL) {
            printf(", ");
        }
        atual = atual->proximo;
    }
    printf("]\n");
}

int linha_indice = 0; // Declaração da variável de contagem de linhas

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
    programa linha {
        linha_indice++; 
        printf("[%d] ", linha_indice); 
        imprimir_pilha();
        }
    | /* vazio */
    ;

linha:
    linha_inicio_bloco
    | linha_fim_bloco
    | linha_declaracao ';'
    | linha_atribuicao ';'
    | linha_print ';'
    | /* vazio */
    ;

linha_inicio_bloco:
    BLOCO_INICIO {
        printf("linha_inicio_bloco --- "); 
        empilhar_escopo();
        }
    ;

linha_fim_bloco:
    BLOCO_FIM {
        printf("linha_fim_bloco --- "); 
        desempilhar_escopo();
        }
    ;

linha_declaracao:
    TIPO_NUMERO IDENTIFICADOR { 
        printf("linha_declaracao\n"); 
        }
    | TIPO_CADEIA lista_declaracao_cadeia { 
        printf("linha_declaracao\n"); 
        }
    | TIPO_NUMERO lista_declaracao_numero { 
        printf("linha_declaracao\n"); 
        }
    ;
    lista_declaracao_cadeia:
        declaracao_cadeia
        | lista_declaracao_cadeia ',' declaracao_cadeia
        ;
    declaracao_cadeia:
        IDENTIFICADOR '=' CADEIA
        | IDENTIFICADOR
        ;
    lista_declaracao_numero:
        declaracao_numero
        | lista_declaracao_numero ',' declaracao_numero
        ;
    declaracao_numero:
        IDENTIFICADOR '=' expressao_numero
        | IDENTIFICADOR
        ;
    expressao_numero:
        NUMERO
        | IDENTIFICADOR
        | expressao_numero '+' NUMERO
        | expressao_numero '+' IDENTIFICADOR
        ;

linha_atribuicao:
    IDENTIFICADOR '=' lista_expressao { printf("linha_atribuicao\n"); }
    | IDENTIFICADOR '=' CADEIA { printf("linha_atribuicao\n"); }
    ;
    lista_expressao:
        expressao
        | lista_expressao '+' expressao
        ;
    expressao:
        NUMERO
        | IDENTIFICADOR
        ;

linha_print:
    PRINT IDENTIFICADOR { printf("linha_print\n"); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int main(void) {
    inicializar_pilha_de_escopos();
    return yyparse();
}
