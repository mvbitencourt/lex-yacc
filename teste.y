%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>

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

typedef union {
    int num_valor;
    char *str_valor;
} ValorVariavel;

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

Variavel* verifica_variavel_existe_pilha(char *identificador) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, identificador) == 0) {
                return var_atual;
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    return NULL;
}

char* verifica_tipo_variavel(char *nome_var) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_var) == 0) {
                return var_atual->tipo;
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: Variável %s não encontrada\n", nome_var);
    return NULL; // Retornar NULL se a variável não for encontrada
}

int busca_valor_variavel_numero(char *nome_var) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_var) == 0) {
                if (var_atual->tipo_valor == TIPO_NUMERO) {
                    return var_atual->valor.num_valor;
                } else {
                    printf("Erro: Variável %s não é do tipo NUMERO\n", nome_var);
                    return 0; // Valor padrão ou tratar erro de outra forma
                }
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: Variável %s não encontrada\n", nome_var);
    return 0; // Valor padrão se a variável não for encontrada
}

char* busca_valor_variavel_cadeia(char *nome_var) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_var) == 0) {
                if (var_atual->tipo_valor == TIPO_CADEIA) {
                    return var_atual->valor.str_valor;
                } else {
                    printf("Erro: Variável %s não é do tipo CADEIA\n", nome_var);
                    return NULL; // Valor padrão ou tratar erro de outra forma
                }
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: Variável %s não encontrada\n", nome_var);
    return NULL; // Valor padrão se a variável não for encontrada
}

char* remove_espacos(const char* str) {
    int i, j;
    int len = strlen(str);
    char* nova_str = (char*)malloc(len + 1); // Aloca memória para a nova string

    if (nova_str == NULL) {
        fprintf(stderr, "Erro de alocação de memória\n");
        exit(1);
    }

    for (i = 0, j = 0; i < len; i++) {
        if (str[i] != ' ') {
            nova_str[j++] = str[i];
        }
    }
    nova_str[j] = '\0'; // Termina a nova string

    return nova_str;
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

%}

%union 
{
	int number;
    char *string;
}

%token BLOCO_INICIO BLOCO_FIM IDENTIFICADOR CADEIA
%token NUMERO
%token TIPO_NUMERO TIPO_CADEIA PRINT

%%

programa:
    programa linha {linha_indice++; printf("[%d] ", linha_indice); imprimir_pilha();}
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
    TIPO_CADEIA lista_declaracao_cadeia  { 
        printf("linha_declaracao\n"); 
    }
    | TIPO_NUMERO lista_declaracao_numero  { 
        printf("linha_declaracao\n"); 
    }
    ;

    lista_declaracao_cadeia:
        declaracao_cadeia
        | lista_declaracao_cadeia ',' declaracao_cadeia
        ;
    declaracao_cadeia:
        IDENTIFICADOR '=' expressao_cadeia { 
            char* s1 = remove_espacos($1.string);
            if (verifica_variavel_existe_pilha(s1) == NULL) {
                adicionar_variavel_cadeia("CADEIA", s1, $3.string);
            }
            else {
                printf("Erro: Variavel '%s' já declarada no escopo\n", s1);
            }
        }
        | IDENTIFICADOR {
            char* s1 = remove_espacos($1.string); 
            if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
                adicionar_variavel_cadeia("CADEIA", s1, "");
            }
            else {
                printf("Erro: Variavel '%s' já declarada no escopo\n", s1);
            }
        }
        ;
    expressao_cadeia:
        CADEIA { 
            $$.string = $1.string; 
        }
        | IDENTIFICADOR { 
            char* s1 = remove_espacos($1.string);
            if(verifica_variavel_existe_pilha(s1) != NULL){
                if(strcmp(verifica_tipo_variavel(s1), "CADEIA") == 0){
                    $$.string = busca_valor_variavel_cadeia(s1); 
                }
                else{
                    printf("Erro: Tipos incompativeis\n");
                }
            }
        }
        | expressao_cadeia '+' CADEIA {
            size_t len1 = strlen($1.string);
            size_t len2 = strlen($3.string);
            char* result = (char*)malloc(len1 + len2 + 1);

            strcpy(result, $1.string);
            strcat(result, $3.string);
 
            $$.string  = result; 
        }
        | expressao_cadeia '+' IDENTIFICADOR {
            char* s3 = remove_espacos($3.string);
            if(verifica_variavel_existe_pilha(s3) != NULL){
                if(strcmp(verifica_tipo_variavel(s3), "CADEIA") == 0){
                    char* valor_variavel_s3 = busca_valor_variavel_cadeia(s3);

                    size_t len1 = strlen($1.string);
                    size_t len2 = strlen(valor_variavel_s3);
                    char* result = (char*)malloc(len1 + len2 + 1);

                    strcpy(result, $1.string);
                    strcat(result, valor_variavel_s3);

                    $$.string  = result;
                }
                else{
                    printf("Erro: Tipos incompativeis\n");
                }
            }
            else{
                printf("Erro: Variavel não declarada\n");
            }
        }

    lista_declaracao_numero:
        declaracao_numero
        | lista_declaracao_numero ',' declaracao_numero
        ;
    declaracao_numero:
        IDENTIFICADOR '=' expressao_numero { 
            char* s1 = remove_espacos($1.string);
            if (verifica_variavel_existe_pilha(s1) == NULL) {
                adicionar_variavel_numero("NUMERO", s1, $3.number);
            }
            else {
                printf("Erro: Variavel '%s' já declarada no escopo\n", s1);
            }
        }
        | IDENTIFICADOR {
            char* s1 = remove_espacos($1.string); 
            if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
                adicionar_variavel_numero("NUMERO", s1, 0);
            }
            else {
                printf("Erro: Variavel '%s' já declarada no escopo\n", s1);
            }
        }
        ;
    expressao_numero:
        NUMERO { 
            $$.number = $1.number; 
        }
        | IDENTIFICADOR { 
            char* s1 = remove_espacos($1.string);
            if(verifica_variavel_existe_pilha(s1) != NULL){
                if(strcmp(verifica_tipo_variavel(s1), "NUMERO") == 0){
                    $$.number = busca_valor_variavel_numero(s1); 
                }
                else{
                    printf("\n\n==== %s ====\n\n", verifica_tipo_variavel(s1));
                    printf("Erro: Tipos incompativeis\n");
                }
            }
        }
        | expressao_numero '+' NUMERO { 
            $$.number  = $1.number + $3.number; 
        }
        | expressao_numero '+' IDENTIFICADOR {
            char* s3 = remove_espacos($3.string);
            if(verifica_variavel_existe_pilha(s3) != NULL){
                if(strcmp(verifica_tipo_variavel(s3), "NUMERO") == 0){
                    int valor_variavel_s3 = busca_valor_variavel_numero(s3);
                    $$.number  = $1.number + valor_variavel_s3; 
                }
                else{
                    printf("Erro: Tipos incompativeis\n");
                }
            }
            else{
                printf("Erro: Variavel não declarada\n");
            }
        }
        ;

linha_atribuicao:
    IDENTIFICADOR '=' lista_expressao_numero { 
        printf("linha_atribuicao\n");
        char* s1 = remove_espacos($1.string); 
        if(verifica_variavel_existe_pilha(s1) != NULL) {
            char* tipo_identificador = verifica_tipo_variavel(s1);
            if (tipo_identificador != NULL) {
                if ((strcmp(tipo_identificador, "NUMERO") == 0)) {
                    adicionar_variavel_numero(tipo_identificador, s1, $3.number);
                }
                else {
                    printf("Erro: Tipos incompatíveis na atribuição\n");
                }
            }
            else {
                printf("Erro: Variável '%s' com tipo invalido\n", s1);
            }
        }
        else{
            printf("Erro: Variável '%s' não declarada\n", s1);
        }
    }
    | IDENTIFICADOR '=' lista_expressao_cadeia { 
        printf("linha_atribuicao\n");
        char* s1 = remove_espacos($1.string); 
        if(verifica_variavel_existe_pilha(s1) != NULL) {
            char* tipo_identificador = verifica_tipo_variavel(s1);
            if (tipo_identificador != NULL) {
                if ((strcmp(tipo_identificador, "CADEIA") == 0)) {
                    adicionar_variavel_cadeia(tipo_identificador, s1, $3.string);
                }
                else {
                    printf("Erro: Tipos incompatíveis na atribuição\n");
                }
            }
            else {
                printf("Erro: Variável '%s' com tipo invalido\n", s1);
            }
        }
        else{
            printf("Erro: Variável '%s' não declarada\n", s1);
        }
    }
    ;
    lista_expressao_numero:
        expressao_numero {
            $$.number = $1.number;
        }
        | lista_expressao_numero '+' expressao_numero {
            $$.number = $1.number + $3.number;
        }
    ;
    expressao_numero:
        NUMERO {
            $$.number = $1.number; 
        }
        | IDENTIFICADOR { 
            char* s1 = $1.string;
            if(verifica_variavel_existe_pilha(s1) != NULL){
                if(strcmp(verifica_tipo_variavel(s1), "NUMERO") == 0){
                    $$.number = busca_valor_variavel_numero(s1); 
                }
                else{
                    printf("Erro: Tipos invalidos\n");
                }
            }
            else{
                printf("Erro: Variavel '%s' não declarada\n", s1);
            }
        }
        ;
    lista_expressao_cadeia:
        expressao_cadeia {
            $$.string = $1.string;
        }
        | lista_expressao_cadeia '+' expressao_cadeia {
            char* s1 = remove_espacos($1.string);
            char* s3 = remove_espacos($3.string);

            size_t len1 = strlen(s1);
            size_t len2 = strlen(s3);
            char* result = (char*)malloc(len1 + len2 + 1);

            strcpy(result, s1);
            strcat(result, s3);

            $$.string  = result;
        }
    ;
    expressao_cadeia:
        CADEIA {
            $$.string = $1.string; 
        }
        | IDENTIFICADOR { 
            char* s1 = $1.string;
            if(verifica_variavel_existe_pilha(s1) != NULL){
                if(strcmp(verifica_tipo_variavel(s1), "CADEIA") == 0){
                    $$.string = busca_valor_variavel_cadeia(s1); 
                }
                else{
                    printf("Erro: Tipos invalidos\n");
                }
            }
            else{
                printf("Erro: Variavel '%s' não declarada\n", s1);
            }
        }
        ;

linha_print:
    PRINT IDENTIFICADOR  { 
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