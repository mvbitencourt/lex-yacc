%{
#include <ctype.h>
#include <regex.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex(void);

typedef enum { 
    TIPO_NUMERO, 
    TIPO_CADEIA 
} TipoValor;

typedef struct Variavel {
    char *tipo;
    char *nome;
    TipoValor tipo_valor;
    union {
        int num_valor;
        char *str_valor;
    } valor;
    char *tipo_linha;
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
        printf("Erro: tentativa de remover escopo inexistente\n");
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
    printf("Erro: variável %s não encontrada\n", nome_var);
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
                    printf("Erro: variável %s não é do tipo NUMERO\n", nome_var);
                    return 0; // Valor padrão ou tratar erro de outra forma
                }
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: variável %s não encontrada\n", nome_var);
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
                    printf("Erro: variável %s não é do tipo CADEIA\n", nome_var);
                    return NULL; // Valor padrão ou tratar erro de outra forma
                }
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: variável %s não encontrada\n", nome_var);
    return NULL; // Valor padrão se a variável não for encontrada
}

char* buscar_tipo_linha(char *nome_variavel) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_variavel) == 0) {
                return var_atual->tipo_linha;
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    return NULL; // Retorna NULL se a variável não for encontrada
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

void adicionar_variavel_numero(char *tipo, char *nome, int num_valor, char *tipo_linha) {
    if (pilha_de_escopos == NULL) {
        printf("Erro: pilha de escopos não inicializada\n");
        return;
    }
    Variavel *nova_variavel = (Variavel *)malloc(sizeof(Variavel));
    nova_variavel->tipo = strdup(tipo);
    nova_variavel->nome = strdup(nome);
    nova_variavel->tipo_valor = TIPO_NUMERO;
    nova_variavel->valor.num_valor = num_valor;

    nova_variavel->tipo_linha = tipo_linha;

    nova_variavel->proximo = pilha_de_escopos->variaveis;
    pilha_de_escopos->variaveis = nova_variavel;
}

void adicionar_variavel_cadeia(char *tipo, char *nome, char *str_valor, char *tipo_linha) {
    if (pilha_de_escopos == NULL) {
        printf("Erro: pilha de escopos não inicializada\n");
        return;
    }
    Variavel *nova_variavel = (Variavel *)malloc(sizeof(Variavel));
    nova_variavel->tipo = strdup(tipo);
    nova_variavel->nome = strdup(nome);
    nova_variavel->tipo_valor = TIPO_CADEIA;
    nova_variavel->valor.str_valor = strdup(str_valor);

    nova_variavel->tipo_linha = tipo_linha;

    nova_variavel->proximo = pilha_de_escopos->variaveis;
    pilha_de_escopos->variaveis = nova_variavel;
}

void atualiza_variavel(char *tipo, char *nome, int num_valor, char *str_valor, char *tipo_linha) {
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome) == 0) {

                // Atualiza os valores conforme o tipo
                if (strcmp(tipo, "NUMERO") == 0) {
                    var_atual->tipo_valor = TIPO_NUMERO;
                    var_atual->valor.num_valor = num_valor;
                } else if (strcmp(tipo, "CADEIA") == 0) {
                    var_atual->tipo_valor = TIPO_CADEIA;
                    if (strcmp(var_atual->tipo, "CADEIA") == 0) {
                        free(var_atual->valor.str_valor);
                    }
                    var_atual->valor.str_valor = strdup(str_valor);
                }
                // Atualiza o tipo da variável
                free(var_atual->tipo);
                var_atual->tipo = strdup(tipo);
                // Atualiza o campo tipo_linha
                var_atual->tipo_linha = strdup(tipo_linha);
                return;
            }
            var_atual = var_atual->proximo;
        }
        escopo_atual = escopo_atual->proximo;
    }
    printf("Erro: variável %s não encontrada.\n", nome);
}

void imprimir_pilha() {
    printf("Pilha = [");
    Escopo *escopo_atual = pilha_de_escopos;
    while (escopo_atual != NULL) {
        printf("[");
        Variavel *var_atual = escopo_atual->variaveis;
        while (var_atual != NULL) {
            if (var_atual->tipo_valor == TIPO_NUMERO) {
                printf("[%s, %s, %d, %s]", var_atual->tipo, var_atual->nome, var_atual->valor.num_valor, var_atual->tipo_linha);
            } else {
                printf("[%s, %s, %s, %s]", var_atual->tipo, var_atual->nome, var_atual->valor.str_valor, var_atual->tipo_linha);
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

char* numero_para_string(int numero) {
    // Aloca memória para armazenar a string resultante
    // Assumindo que o número não terá mais de 50 caracteres
    char *buffer = (char *)malloc(50 * sizeof(char));
    if (buffer != NULL) {
        sprintf(buffer, "%d", numero);
    }
    return buffer;
}

int regex_match(char *str, char *pattern) {
    regex_t regex;
    int reti;

    // Compila a expressão regular
    reti = regcomp(&regex, pattern, REG_EXTENDED);
    if (reti) {
        fprintf(stderr, "Não foi possível compilar a expressão regular\n");
        return 0;
    }

    // Executa a correspondência da expressão regular
    reti = regexec(&regex, str, 0, NULL, 0);
    regfree(&regex);

    // Retorna 1 se corresponder, 0 caso contrário
    return !reti;
}

char* verificar_tipo(char *str) {
    // Expressão regular para números
    char *numero_regex = "^[+-]?[0-9]+(\\.[0-9]+)?$";
    // Expressão regular para cadeias
    char *cadeia_regex = "^\"([^\"]*)\"$";

    if (regex_match(str, numero_regex)) {
        return "NUMERO";
    } else if (regex_match(str, cadeia_regex)) {
        return "CADEIA";
    } else {
        return "DESCONHECIDO";
    }
}

char* retira_ultimo_digito(char *str) {
    size_t len = strlen(str); // Obter o comprimento da string

    if (len == 0) {
        return NULL; // Retornar NULL se a string estiver vazia
    }

    // Alocar memória para a nova string, excluindo o último caractere (a aspas de fechamento)
    char *nova_str = (char *)malloc(len * sizeof(char));
    if (nova_str == NULL) {
        fprintf(stderr, "Erro ao alocar memória\n");
        return NULL;
    }

    // Copiar a string original para a nova string, excluindo o último caractere
    strncpy(nova_str, str, len - 1);
    nova_str[len - 1] = '\0'; // Adicionar o caractere nulo terminador

    return nova_str;
}

char* retira_primeiro_digito(char *str) {
    size_t len = strlen(str); // Obter o comprimento da string

    if (len <= 1) {
        return NULL; // Retornar NULL se a string estiver vazia ou tiver apenas um caractere
    }

    // Alocar memória para a nova string, excluindo o primeiro caractere (a aspas de abertura)
    char *nova_str = (char *)malloc(len * sizeof(char));
    if (nova_str == NULL) {
        fprintf(stderr, "Erro ao alocar memória\n");
        return NULL;
    }

    // Copiar a string original para a nova string, excluindo o primeiro caractere
    strcpy(nova_str, str + 1);

    return nova_str;
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
            adicionar_variavel_cadeia("CADEIA", s1, $3.string, "linha_declaracao");
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                    adicionar_variavel_cadeia("CADEIA", s1, $3.string, "linha_declaracao");
            }
            else {
                if(strcmp(buscar_tipo_linha(s1), "linha_atribuicao") == 0){
                    atualiza_variavel("CADEIA", s1, 0, $3.string, "linha_declaracao");
                }
                else{
                    printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
                }
            }
        }
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string); 
        if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
            adicionar_variavel_cadeia("CADEIA", s1, "", "linha_declaracao");
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                    adicionar_variavel_cadeia("CADEIA", s1, "", "linha_declaracao");
            }
            else {
                if(strcmp(buscar_tipo_linha(s1), "linha_atribuicao") == 0){
                    atualiza_variavel("CADEIA", s1, 0, "", "linha_declaracao");
                }
                else{
                    printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
                }
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
                printf("[%d] Erro: tipos não compatíveis\n", linha_indice);
            }
        }
    }
    | expressao_cadeia '+' CADEIA {
        char* s1 = retira_ultimo_digito($1.string);
        char* s3 = remove_espacos_fora_aspas($3.string);
        s3 = retira_primeiro_digito(s3);
        size_t len1 = strlen(s1);
        size_t len2 = strlen(s3);
        char* result = (char*)malloc(len1 + len2 + 1);

        strcpy(result, s1);
        strcat(result, s3);

        $$.string  = result;
    }
    | expressao_cadeia '+' IDENTIFICADOR {
        char* s3 = remove_espacos($3.string);
        if(verifica_variavel_existe_pilha(s3) != NULL){
            if(strcmp(verifica_tipo_variavel(s3), "CADEIA") == 0){
                char* s1 = retira_ultimo_digito($1.string);
                char* valor_variavel_s3 = busca_valor_variavel_cadeia(s3);
                valor_variavel_s3 = retira_primeiro_digito(valor_variavel_s3);

                size_t len1 = strlen(s1);
                size_t len2 = strlen(valor_variavel_s3);
                char* result = (char*)malloc(len1 + len2 + 1);

                strcpy(result, s1);
                strcat(result, valor_variavel_s3);

                $$.string  = result;
            }
            else{
                printf("[%d] Erro: tipos não compatíveis\n", linha_indice);
            }
        }
        else{
            printf("[%d] Erro: variável não declarada\n", linha_indice);
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
            adicionar_variavel_numero("NUMERO", s1, $3.number, "linha_declaracao");
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_numero("NUMERO", s1, $3.number, "linha_declaracao");
            }
            else {
                if(strcmp(buscar_tipo_linha(s1), "linha_atribuicao") == 0){
                    atualiza_variavel("NUMERO", s1, $3.number, "", "linha_declaracao");
                }
                else{
                    printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
                }
            }
        }
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string); 
        if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
            adicionar_variavel_numero("NUMERO", s1, 0, "linha_declaracao");
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_numero("NUMERO", s1, 0, "linha_declaracao");
            }
            else {
                if(strcmp(buscar_tipo_linha(s1), "linha_atribuicao") == 0){
                    atualiza_variavel("NUMERO", s1, 0, "", "linha_declaracao");
                }
                else{
                    printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
                }
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
                printf("[%d] Erro: tipos não compatíveis\n", linha_indice);
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
                printf("[%d] Erro: tipos não compatíveis\n", linha_indice);
            }
        }
        else{
            printf("[%d] Erro: variável não declarada\n", linha_indice);
        }
    }
    ;

linha_atribuicao:
    IDENTIFICADOR '=' expressao {
        char* tipo_expressao = verificar_tipo($3.string);
        char* s1 = remove_espacos($1.string);
        if (verifica_variavel_existe_pilha(s1) != NULL) {
            char* tipo_variavel = verifica_tipo_variavel(s1);
            tipo_expressao = verificar_tipo($3.string);
            if (strcmp(tipo_variavel, tipo_expressao) == 0) {
                if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                    if (strcmp(tipo_expressao, "NUMERO") == 0){
                        int expressao_number = atoi($3.string);
                        adicionar_variavel_numero("NUMERO", s1, expressao_number, "linha_atribuicao");
                    }
                    else if (strcmp(tipo_expressao, "CADEIA") == 0){
                        adicionar_variavel_cadeia("CADEIA", s1, $3.string, "linha_atribuicao");
                    }
                }
                else {
                    if (strcmp(tipo_expressao, "NUMERO") == 0){
                        int expressao_number = atoi($3.string);
                        atualiza_variavel("NUMERO", s1, expressao_number, "", "linha_declaracao");
                    }
                    else if (strcmp(tipo_expressao, "CADEIA") == 0){
                        char* nova_cadeia;
                        nova_cadeia = (char *)malloc((strlen($3.string) + 1) * sizeof(char));
                        strcpy(nova_cadeia, $3.string);
                        atualiza_variavel("CADEIA", s1, 0, nova_cadeia, "linha_declaracao");
                        free(nova_cadeia);
                    }
                    else{
                        printf("[%d] Erro: tipo inválido\n", linha_indice);
                    }
                }
            }
            else {
                printf("[%d] Erro: tipos não compatíveis\n", linha_indice);
            }
        } else {
            printf("[%d] Erro: variável '%s' não declarada\n", linha_indice, s1);
        }
    }
expressao:
    NUMERO {
        $$.string = numero_para_string($1.number);
    }
    | CADEIA {
        char* s1 = remove_espacos_fora_aspas($1.string);
        $$.string = s1;
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string);
        if (verifica_variavel_existe_pilha(s1) != NULL) {
            char* tipo_variavel = verifica_tipo_variavel(s1);
            if(strcmp(tipo_variavel, "NUMERO") == 0){
                int valor_variavel_s1 = busca_valor_variavel_numero(s1);
                $$.string = numero_para_string(valor_variavel_s1);
            }
            else if(strcmp(tipo_variavel, "CADEIA") == 0){
                char* valor_variavel_s1 = busca_valor_variavel_cadeia(s1);
                $$.string = valor_variavel_s1;
            }
            else {
                printf("[%d] Erro: variável '%s' com tipo inválido\n", linha_indice, s1);
            }
        } 
        else {
            printf("[%d] Erro: variável '%s' não declarada\n", linha_indice, s1);
        }
    }
    | expressao '+' NUMERO {
        char* tipo_expressao = verificar_tipo($1.string);
        if (strcmp(tipo_expressao, "NUMERO") == 0 ) {
            int soma = atoi($1.string) + $3.number;
            $$.string = numero_para_string(soma);
        } else {
           printf("[%d] Erro: Tipos incompatíveis\n", linha_indice);
        }
    }
    | expressao '+' CADEIA {
        char* tipo_expressao = verificar_tipo($1.string);
        if (strcmp(tipo_expressao, "CADEIA") == 0) {
            char* s1 = retira_ultimo_digito($1.string);
            char* s3 = remove_espacos_fora_aspas($3.string);
            s3 = retira_primeiro_digito(s3);

            size_t len1 = strlen(s1);
            size_t len2 = strlen(s3);
            char* result = (char*)malloc(len1 + len2 + 1);

            strcpy(result, s1);
            strcat(result, s3);

            $$.string  = result;
        } 
        else {
           printf("[%d] Erro: Tipos incompatíveis\n", linha_indice);
        }
    }
    | expressao '+' IDENTIFICADOR {
        char* tipo_expressao = verificar_tipo($1.string);
        char* s3 = remove_espacos($3.string);
        if (verifica_variavel_existe_pilha(s3) != NULL) {
            char* tipo_variavel = verifica_tipo_variavel(s3);
            if (strcmp(tipo_expressao, tipo_variavel) == 0){
                if (strcmp(tipo_expressao, "NUMERO") == 0) {
                    int valor_variavel_s3 = busca_valor_variavel_numero(s3);
                    int soma = atoi($1.string) + valor_variavel_s3;
                    $$.string = numero_para_string(soma);
                }
                else if (strcmp(tipo_expressao, "CADEIA") == 0){
                    char* s1 = retira_ultimo_digito($1.string);
                    char* valor_variavel_s3 = busca_valor_variavel_cadeia(s3);
                    valor_variavel_s3 = retira_primeiro_digito(valor_variavel_s3);

                    size_t len1 = strlen(s1);
                    size_t len2 = strlen(valor_variavel_s3);
                    char* result = (char*)malloc(len1 + len2 + 1);

                    strcpy(result, s1);
                    strcat(result, valor_variavel_s3);

                    $$.string  = result;
                }
            }
            else {
                printf("[%d] Erro: tipos não compatíveis\n", linha_indice);
            }
        }
        else {
            printf("[%d] Erro: variável '%s' não declarada\n", linha_indice, s3);
        }

    }

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
            printf("[%d] Erro: variável não declarada\n", linha_indice);
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