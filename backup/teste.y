%{
#include <ctype.h>
#include <regex.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

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
}

void desempilhar_escopo() {
    if (pilha_de_escopos != NULL) {
        Escopo *escopo_antigo = pilha_de_escopos;
        pilha_de_escopos = pilha_de_escopos->proximo;
        free(escopo_antigo);
    } else {
        printf("Erro: Tentativa de remover escopo inexistente\n");
    }
}

void inicializar_pilha_de_escopos() {
    pilha_de_escopos = NULL;
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

Variavel* verifica_variavel_existe_escopo_atual(char *identificador) {
    if (pilha_de_escopos == NULL) {
        return NULL;
    }

    Variavel *var_atual = pilha_de_escopos->variaveis;
    while (var_atual != NULL) {
        if (strcmp(var_atual->nome, identificador) == 0) {
            return var_atual;
        }
        var_atual = var_atual->proximo;
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

char* verifica_tipo_expressao(char* expressao) {
    regex_t regex_numero;
    regex_t regex_cadeia;
    int reti;

    // Expressão regular para NUMERO
    reti = regcomp(&regex_numero, "^[+-]?[0-9]+$", REG_EXTENDED);
    if (reti) {
        fprintf(stderr, "Could not compile regex\n");
        return NULL;
    }

    // Expressão regular para CADEIA
    reti = regcomp(&regex_cadeia, "^\"[^\"]*\"$", REG_EXTENDED);
    if (reti) {
        fprintf(stderr, "Could not compile regex\n");
        return NULL;
    }

    // Verifica se a expressão é um NUMERO
    reti = regexec(&regex_numero, expressao, 0, NULL, 0);
    if (!reti) {
        regfree(&regex_numero);
        regfree(&regex_cadeia);
        return "NUMERO";
    }

    // Verifica se a expressão é uma CADEIA
    reti = regexec(&regex_cadeia, expressao, 0, NULL, 0);
    if (!reti) {
        regfree(&regex_numero);
        regfree(&regex_cadeia);
        return "CADEIA";
    }

    // Libera a memória das expressões regulares
    regfree(&regex_numero);
    regfree(&regex_cadeia);

    return "DESCONHECIDO";
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


char* remove_espacos_fora_aspas( char* str) {
    int len = strlen(str);
    char* nova_str = (char*)malloc(len + 1); // Aloca memória para a nova string
    if (nova_str == NULL) {
        fprintf(stderr, "Erro de alocação de memória\n");
        exit(1);
    }

    int i, j = 0;
    int dentro_aspas = 0; // Flag para rastrear se estamos dentro de aspas

    for (i = 0; i < len; i++) {
        if (str[i] == '"') {
            dentro_aspas = !dentro_aspas; // Alterna o estado dentro/fora de aspas
        }

        if (dentro_aspas || (!dentro_aspas && str[i] != ' ')) {
            nova_str[j++] = str[i];
        }
    }
    nova_str[j] = '\0'; // Termina a nova string

    return nova_str;
}

char* concatenar_strings(char* str1, char* str2) {
    int len1 = strlen(str1);
    int len2 = strlen(str2);

    // Remover a aspa final de str1 e a aspa inicial de str2
    char* str1_sem_aspas = strndup(str1, len1 - 1);
    char* str2_sem_aspas = strdup(str2 + 1);

    // Alocar memória para a string resultante
    char* resultado = (char*)malloc(len1 + len2 - 1); // -1 para compensar as aspas removidas
    if (resultado == NULL) {
        fprintf(stderr, "Erro de alocação de memória\n");
        exit(1);
    }

    // Construir a string resultante
    strcpy(resultado, "\"");
    strcat(resultado, str1_sem_aspas);
    strcat(resultado, str2_sem_aspas);
    strcat(resultado, "\"");

    // Liberar a memória alocada para as strings temporárias
    free(str1_sem_aspas);
    free(str2_sem_aspas);

    return resultado;
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

void atualiza_variavel(char *tipo, char *nome, int num_valor, char *str_valor) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome) == 0) {
                free(var_atual->tipo);
                var_atual->tipo = strdup(tipo);
                if (strcmp(tipo, "NUMERO") == 0) {
                    var_atual->tipo_valor = TIPO_NUMERO;
                    var_atual->valor.num_valor = num_valor;
                } else if (strcmp(tipo, "CADEIA") == 0) {
                    var_atual->tipo_valor = TIPO_CADEIA;
                    free(var_atual->valor.str_valor);
                    var_atual->valor.str_valor = strdup(str_valor);
                }
                return;
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: Variável %s não encontrada.\n", nome);
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
    //Expressao *expr;
}

%token BLOCO_INICIO BLOCO_FIM IDENTIFICADOR CADEIA
%token NUMERO
%token TIPO_NUMERO TIPO_CADEIA PRINT

//%type <expr> expressao

%%

programa:
    programa linha {linha_indice++; /*printf("[%d] ", linha_indice); imprimir_pilha();*/}
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
        empilhar_escopo();
    }
    ;

linha_fim_bloco:
    BLOCO_FIM {
        desempilhar_escopo();
    }
    ;

linha_declaracao:
    TIPO_CADEIA lista_declaracao_cadeia
    | TIPO_NUMERO lista_declaracao_numero
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
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                    adicionar_variavel_cadeia("CADEIA", s1, $3.string);
            }
            else {
                printf("[%d] Erro: Variavel '%s' já declarada no escopo\n", linha_indice, s1);
            }
        }
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string); 
        if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
            adicionar_variavel_cadeia("CADEIA", s1, "");
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                    adicionar_variavel_cadeia("CADEIA", s1, "");
            }
            else {
                printf("[%d] Erro: Variavel '%s' já declarada no escopo\n", linha_indice, s1);
            }
        }
    }
    ;
expressao_cadeia:
    CADEIA { 
        char* s1 = remove_espacos_fora_aspas($1.string);
        $$.string = s1;
    }
    | IDENTIFICADOR { 
        char* s1 = remove_espacos($1.string);
        if(verifica_variavel_existe_pilha(s1) != NULL){
            if(strcmp(verifica_tipo_variavel(s1), "CADEIA") == 0){
                $$.string = busca_valor_variavel_cadeia(s1); 
            }
            else{
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }
    }
    | expressao_cadeia '+' CADEIA {
        char* s3 = remove_espacos_fora_aspas($3.string);
        size_t len1 = strlen($1.string);
        size_t len2 = strlen(s3);
        char* result = (char*)malloc(len1 + len2 + 1);

        strcpy(result, $1.string);
        strcat(result, s3);

        $$.string  = result;

        //$$.string  = concatenar_strings($1.string, $3.string);
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
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }
        else{
            printf("[%d] Erro: Variavel não declarada\n", linha_indice);
        }
    }
    ;
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
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_numero("NUMERO", s1, $3.number);
            }
            else {
                printf("[%d] Erro: Variavel '%s' já declarada no escopo\n", linha_indice, s1);
            }
        }
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string); 
        if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
            adicionar_variavel_numero("NUMERO", s1, 0);
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_numero("NUMERO", s1, 0);
            }
            else {
                printf("[%d] Erro: Variavel '%s' já declarada no escopo\n", linha_indice, s1);
            }
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
                //$$.string = busca_valor_variavel_numero(s1); 
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
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
                //char* valor_variavel_s3 = busca_valor_variavel_numero(s3);
                //$$.string  = $1.number + valor_variavel_s3; 
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }
        else{
            printf("[%d] Erro: Variavel não declarada\n", linha_indice);
        }
    }
    ;

linha_atribuicao:
    IDENTIFICADOR '=' expressao_numero_atribuicao {
        char* s1 = remove_espacos($1.string);
        if (verifica_variavel_existe_pilha(s1) != NULL) {
            char* tipo_variavel = verifica_tipo_variavel(s1);
            if (strcmp(tipo_variavel, "NUMERO") == 0) {
                if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                    adicionar_variavel_numero("NUMERO", s1, $3.number);
                }
                else {
                    atualiza_variavel("NUMERO", s1, $3.number, "");
                }
            }
            else {
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        } else {
            printf("[%d] Erro: Variavel '%s' não declarada\n", linha_indice, s1);
        }
    }
    | IDENTIFICADOR '=' expressao_cadeia_atribuicao {
        char* s1 = remove_espacos($1.string);
        if (verifica_variavel_existe_pilha(s1) != NULL) {
            char* tipo_variavel = verifica_tipo_variavel(s1);
            if (strcmp(tipo_variavel, "CADEIA") == 0) {
                if (verifica_variavel_existe_escopo_atual(s1) == NULL) {
                    adicionar_variavel_cadeia("CADEIA", s1, $3.string);
                }
                else {
                    atualiza_variavel("CADEIA", s1, 0, $3.string);
                }
            }
            else {
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }else {
            printf("[%d] Erro: Variavel '%s' não declarada\n", linha_indice, s1);
        }
    }
    ;
expressao_numero_atribuicao:
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
                //$$.string = busca_valor_variavel_numero(s1); 
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
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
                //char* valor_variavel_s3 = busca_valor_variavel_numero(s3);
                //$$.string  = $1.number + valor_variavel_s3; 
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }
        else{
            printf("[%d] Erro: Variavel não declarada\n", linha_indice);
        }
    }
    ;
expressao_cadeia_atribuicao:
    CADEIA { 
        char* s1 = remove_espacos_fora_aspas($1.string);
        $$.string = s1;
    }
    | IDENTIFICADOR { 
        char* s1 = remove_espacos($1.string);
        if(verifica_variavel_existe_pilha(s1) != NULL){
            if(strcmp(verifica_tipo_variavel(s1), "CADEIA") == 0){
                $$.string = busca_valor_variavel_cadeia(s1); 
            }
            else{
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }
    }
    | expressao_cadeia '+' CADEIA {
        char* s3 = remove_espacos_fora_aspas($3.string);
        size_t len1 = strlen($1.string);
        size_t len2 = strlen(s3);
        char* result = (char*)malloc(len1 + len2 + 1);

        strcpy(result, $1.string);
        strcat(result, s3);

        $$.string  = result;

        //$$.string  = concatenar_strings($1.string, $3.string);
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
                printf("[%d] Erro: Tipos incompativeis\n", linha_indice);
            }
        }
        else{
            printf("[%d] Erro: Variavel não declarada\n", linha_indice);
        }
    }
    ;

/*
expressao:
    expressao_numero {
        $$.number = $1.number;
    }
    | expressao_cadeia {
        printf("\nPASSOU AQUI\n");
        $$.string = $1.string;
    }
    ;
*/

linha_print:
    PRINT IDENTIFICADOR  { 
        char* s2 = remove_espacos($2.string);

        if(verifica_variavel_existe_pilha(s2) != NULL){
            if(strcmp(verifica_tipo_variavel(s2), "NUMERO") == 0){
                printf("[%d] %d\n", linha_indice, busca_valor_variavel_numero(s2));
            }
            else{
                printf("[%d] %s\n", linha_indice, busca_valor_variavel_cadeia(s2));
            }
        }
        else {
            printf("[%d] Erro: Variavel não declarada\n", linha_indice);
        }
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