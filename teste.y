%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

typedef enum { TIPO_NUMERO, TIPO_CADEIA } TipoValor;

typedef struct Variavel {
    char *tipo;
    char *nome;
    TipoValor tipo_valor;
    union {
        int num_valor;
        char *str_valor;
    } valor;
    struct Variavel *proximo;
} Variavel;

typedef struct Escopo {
    Variavel *variaveis;
    struct Escopo *proximo;
} Escopo;

Escopo *pilha_de_escopos = NULL;

void empilhar_escopo() {
    Escopo *novo_escopo = (Escopo *)malloc(sizeof(Escopo));
    novo_escopo->variaveis = NULL;
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

void adicionar_variavel_numero(char *tipo, char *nome, int num_valor) {
    if (pilha_de_escopos == NULL) {
        printf("Erro: Pilha de escopos não inicializada\n");
        return;
    }
    Variavel *nova_variavel = (Variavel *)malloc(sizeof(Variavel));
    nova_variavel->tipo = strdup(tipo);
    nova_variavel->nome = strdup(nome);
    nova_variavel->tipo_valor = TIPO_NUMERO;
    nova_variavel->valor.num_valor = num_valor;
    nova_variavel->proximo = pilha_de_escopos->variaveis;
    pilha_de_escopos->variaveis = nova_variavel;
}

void adicionar_variavel_cadeia(char *tipo, char *nome, char *str_valor) {
    if (pilha_de_escopos == NULL) {
        printf("Erro: Pilha de escopos não inicializada\n");
        return;
    }
    Variavel *nova_variavel = (Variavel *)malloc(sizeof(Variavel));
    nova_variavel->tipo = strdup(tipo);
    nova_variavel->nome = strdup(nome);
    nova_variavel->tipo_valor = TIPO_CADEIA;
    nova_variavel->valor.str_valor = strdup(str_valor);
    nova_variavel->proximo = pilha_de_escopos->variaveis;
    pilha_de_escopos->variaveis = nova_variavel;
}

void imprimir_pilha() {
    printf("Pilha = [");
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        printf("[");
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (var_atual->tipo_valor == TIPO_NUMERO) {
                printf("[%s, %s, %d]", var_atual->tipo, var_atual->nome, var_atual->valor.num_valor);
            } else {
                printf("[%s, %s, %s]", var_atual->tipo, var_atual->nome, var_atual->valor.str_valor);
            }
            var_atual = var_atual->proximo;
            if (var_atual != NULL) {
                printf(", ");
            }
        }
        printf("]");
        escopo_atual = escopo_atual->proximo;
        if (escopo_atual != NULL) {
            printf(", ");
        }
    }
    printf("]\n");
}

int linha_indice = 0; // Declaração da variável de contagem de linhas
int tipo_var = 0;
char* nome_var;
int valor_var_num = 0;
char* valor_var_cad;

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
    programa linha {linha_indice++; printf("[%d] ", linha_indice); imprimir_pilha();}
    | /* vazio */
    ;

linha:
    linha_inicio_bloco
    | linha_fim_bloco
    | linha_declaracao
    | linha_atribuicao
    | linha_print
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
    TIPO_NUMERO IDENTIFICADOR ';' { 
        printf("linha_declaracao\n"); 
        adicionar_variavel_numero("NUMERO", $2, 0); 
        }
    | TIPO_CADEIA lista_declaracao_cadeia ';' { 
        printf("linha_declaracao\n"); 
        }
    | TIPO_NUMERO lista_declaracao_numero ';' { 
        printf("linha_declaracao\n"); 
        }
    ;

lista_declaracao_cadeia:
    declaracao_cadeia
    | lista_declaracao_cadeia ',' declaracao_cadeia
    ;

declaracao_cadeia:
    IDENTIFICADOR '=' CADEIA { 
        adicionar_variavel_cadeia("CADEIA", $1, $3); 
        }
    | IDENTIFICADOR { 
        adicionar_variavel_cadeia("CADEIA", $1, ""); 
        }
    ;

lista_declaracao_numero:
    declaracao_numero
    | lista_declaracao_numero ',' declaracao_numero
    ;

declaracao_numero:
    IDENTIFICADOR '=' expressao_numero { 
        adicionar_variavel_numero("NUMERO", $1, $3); 
        }
    | IDENTIFICADOR { 
        adicionar_variavel_numero("NUMERO", $1, 0); 
        }
    ;

expressao_numero:
    NUMERO { 
        $$ = $1; 
        }
    | IDENTIFICADOR { 
        $$ = 0; 
        }
    | expressao_numero '+' NUMERO { 
        $$ = $1 + $3; 
        }
    /*
    | expressao_numero '+' IDENTIFICADOR { 
        Buscar valor de IDENTIFICADOR na pilha
        }
    */
    ;

linha_atribuicao:
    IDENTIFICADOR '=' lista_expressao ';' { 
        printf("linha_atribuicao\n"); 
        }
    | IDENTIFICADOR '=' CADEIA ';' { 
        printf("linha_atribuicao\n"); 
        }
    ;

lista_expressao:
    expressao
    | lista_expressao '+' expressao
    ;

expressao:
    NUMERO { 
        $$ = $1; 
        }
    | IDENTIFICADOR { 
        $$ = 0; 
        }
    ;

linha_print:
    PRINT IDENTIFICADOR ';' { 
        printf("linha_print\n"); 
        }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int main(void) {
    inicializar_pilha_de_escopos();
    return yyparse();
}