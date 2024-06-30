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
    struct Variavel *proximo;
} Variavel;

typedef struct Escopo {
    Variavel *variaveis;
    struct Escopo *proximo;
} Escopo;

Escopo *pilha_de_escopos = NULL;

void empilhar_escopo() {
    Escopo *novo_escopo = (Escopo *)malloc(sizeof(Escopo)); // Aloca memória para um novo escopo
    novo_escopo->variaveis = NULL; // Inicializa a lista de variáveis do novo escopo
    novo_escopo->proximo = pilha_de_escopos; // Define o próximo escopo como o escopo atual da pilha
    pilha_de_escopos = novo_escopo; // Coloca o novo escopo no topo da pilha
}

void desempilhar_escopo() {
    if (pilha_de_escopos != NULL) {
        Escopo *escopo_antigo = pilha_de_escopos; // Guarda o escopo atual para liberar memória depois
        pilha_de_escopos = pilha_de_escopos->proximo; // Atualiza o topo da pilha para o próximo escopo
        free(escopo_antigo); // Libera a memória do escopo antigo
    } else {
        printf("Erro: tentativa de remover escopo inexistente\n");
    }
}

void inicializar_pilha_de_escopos() {
    pilha_de_escopos = NULL; // Inicializa a pilha de escopos como vazia
}

Variavel* verifica_variavel_existe_pilha(char *identificador) {
    Escopo *escopo_atual = pilha_de_escopos; // Começa pelo escopo atual
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis; // Itera pelas variáveis do escopo atual
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, identificador) == 0) {
                return var_atual; // Retorna a variável se encontrada
            }
            var_atual = var_atual->proximo; // Move para a próxima variável
        }
        escopo_atual = escopo_atual->proximo; // Move para o próximo escopo
    }
    return NULL; // Retorna NULL se a variável não for encontrada
}

Variavel* verifica_variavel_existe_escopo_atual(char *identificador) {
    if (pilha_de_escopos == NULL) {
        return NULL; // Retorna NULL se a pilha de escopos estiver vazia
    }

    Variavel *var_atual = pilha_de_escopos->variaveis; // Começa pela variável do escopo atual
    while (var_atual != NULL) {
        if (strcmp(var_atual->nome, identificador) == 0) {
            return var_atual; // Retorna a variável se encontrada
        }
        var_atual = var_atual->proximo; // Move para a próxima variável
    }

    return NULL; // Retorna NULL se a variável não for encontrada
}

char* verifica_tipo_variavel(char *nome_var) {
    Escopo *escopo_atual = pilha_de_escopos; // Começa pelo escopo atual
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis; // Itera pelas variáveis do escopo atual
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_var) == 0) {
                return var_atual->tipo; // Retorna o tipo da variável se encontrada
            }
            var_atual = var_atual->proximo; // Move para a próxima variável
        }
        escopo_atual = escopo_atual->proximo; // Move para o próximo escopo
    }
    printf("Erro: variável %s não encontrada\n", nome_var);
    return NULL; // Retorna NULL se a variável não for encontrada
}

int busca_valor_variavel_numero(char *nome_var) {
    Escopo *escopo_atual = pilha_de_escopos; // Começa pelo escopo atual
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis; // Itera pelas variáveis do escopo atual
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_var) == 0) {
                if (var_atual->tipo_valor == TIPO_NUMERO) {
                    return var_atual->valor.num_valor; // Retorna o valor se for do tipo NUMERO
                } else {
                    printf("Erro: variável %s não é do tipo NUMERO\n", nome_var);
                    return 0; // Valor padrão ou tratar erro de outra forma
                }
            }
            var_atual = var_atual->proximo; // Move para a próxima variável
        }
        escopo_atual = escopo_atual->proximo; // Move para o próximo escopo
    }
    printf("Erro: variável %s não encontrada\n", nome_var);
    return 0; // Valor padrão se a variável não for encontrada
}

char* busca_valor_variavel_cadeia(char *nome_var) {
    Escopo *escopo_atual = pilha_de_escopos; // Começa pelo escopo atual
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis; // Itera pelas variáveis do escopo atual
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome_var) == 0) {
                if (var_atual->tipo_valor == TIPO_CADEIA) {
                    return var_atual->valor.str_valor; // Retorna o valor se for do tipo CADEIA
                } else {
                    printf("Erro: variável %s não é do tipo CADEIA\n", nome_var);
                    return NULL; // Valor padrão ou tratar erro de outra forma
                }
            }
            var_atual = var_atual->proximo; // Move para a próxima variável
        }
        escopo_atual = escopo_atual->proximo; // Move para o próximo escopo
    }
    printf("Erro: variável %s não encontrada\n", nome_var);
    return NULL; // Valor padrão se a variável não for encontrada
}

char* remove_espacos(const char* str) {
    int i, j;
    int len = strlen(str); // Obtém o comprimento da string
    char* nova_str = (char*)malloc(len + 1); // Aloca memória para a nova string

    if (nova_str == NULL) {
        fprintf(stderr, "Erro de alocação de memória\n");
        exit(1);
    }

    for (i = 0, j = 0; i < len; i++) {
        if (str[i] != ' ' && str[i] != '\t') { // Verifica espaços e tabulações
            nova_str[j++] = str[i];
        }
    }
    nova_str[j] = '\0'; // Termina a nova string

    return nova_str; // Retorna a nova string
}

char* remove_espacos_fora_aspas(const char* str) {
    int len = strlen(str); // Obtém o comprimento da string
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

        if (dentro_aspas || (!dentro_aspas && str[i] != ' ' && str[i] != '\t')) {
            nova_str[j++] = str[i];
        }
    }
    nova_str[j] = '\0'; // Termina a nova string

    return nova_str; // Retorna a nova string
}

void adicionar_variavel_numero(char *tipo, char *nome, int num_valor) {
    if (pilha_de_escopos == NULL) {
        printf("Erro: pilha de escopos não inicializada\n");
        return;
    }
    Variavel *nova_variavel = (Variavel *)malloc(sizeof(Variavel)); // Aloca memória para uma nova variável
    nova_variavel->tipo = strdup(tipo); // Duplica o tipo da variável
    nova_variavel->nome = strdup(nome); // Duplica o nome da variável
    nova_variavel->tipo_valor = TIPO_NUMERO; // Define o tipo de valor como NUMERO
    nova_variavel->valor.num_valor = num_valor; // Define o valor numérico

    nova_variavel->proximo = pilha_de_escopos->variaveis; // Coloca a nova variável no início da lista
    pilha_de_escopos->variaveis = nova_variavel; // Atualiza a lista de variáveis do escopo atual
}

void adicionar_variavel_cadeia(char *tipo, char *nome, char *str_valor) {
    if (pilha_de_escopos == NULL) {
        printf("Erro: pilha de escopos não inicializada\n");
        return;
    }
    Variavel *nova_variavel = (Variavel *)malloc(sizeof(Variavel)); // Aloca memória para uma nova variável
    nova_variavel->tipo = strdup(tipo); // Duplica o tipo da variável
    nova_variavel->nome = strdup(nome); // Duplica o nome da variável
    nova_variavel->tipo_valor = TIPO_CADEIA; // Define o tipo de valor como CADEIA
    nova_variavel->valor.str_valor = strdup(str_valor); // Duplica o valor da cadeia

    nova_variavel->proximo = pilha_de_escopos->variaveis; // Coloca a nova variável no início da lista
    pilha_de_escopos->variaveis = nova_variavel; // Atualiza a lista de variáveis do escopo atual
}

void atualiza_variavel(char *tipo, char *nome, int num_valor, char *str_valor) {
    Escopo *escopo_atual = pilha_de_escopos; // Começa pelo escopo atual
    while (escopo_atual != NULL) {
        Variavel *var_atual = escopo_atual->variaveis; // Itera pelas variáveis do escopo atual
        while (var_atual != NULL) {
            if (strcmp(var_atual->nome, nome) == 0) {

                // Atualiza os valores conforme o tipo
                if (strcmp(tipo, "NUMERO") == 0) {
                    var_atual->tipo_valor = TIPO_NUMERO; // Atualiza o tipo de valor
                    var_atual->valor.num_valor = num_valor; // Atualiza o valor numérico
                } else if (strcmp(tipo, "CADEIA") == 0) {
                    var_atual->tipo_valor = TIPO_CADEIA; // Atualiza o tipo de valor
                    if (strcmp(var_atual->tipo, "CADEIA") == 0) {
                        free(var_atual->valor.str_valor); // Libera a memória da cadeia antiga
                    }
                    var_atual->valor.str_valor = strdup(str_valor); // Atualiza o valor da cadeia
                }
                // Atualiza o tipo da variável
                free(var_atual->tipo); // Libera a memória do tipo antigo
                var_atual->tipo = strdup(tipo); // Atualiza o tipo
                return;
            }
            var_atual = var_atual->proximo; // Move para a próxima variável
        }
        escopo_atual = escopo_atual->proximo; // Move para o próximo escopo
    }
    printf("Erro: variável %s não encontrada.\n", nome);
}

void imprimir_pilha() {
    printf("Pilha = [");
    Escopo *escopo_atual = pilha_de_escopos; // Começa pelo escopo atual
    while (escopo_atual != NULL) {
        printf("[");
        Variavel *var_atual = escopo_atual->variaveis; // Itera pelas variáveis do escopo atual
        while (var_atual != NULL) {
            if (var_atual->tipo_valor == TIPO_NUMERO) {
                printf("[%s, %s, %d]", var_atual->tipo, var_atual->nome, var_atual->valor.num_valor);
            } else {
                printf("[%s, %s, %s]", var_atual->tipo, var_atual->nome, var_atual->valor.str_valor);
            }
            var_atual = var_atual->proximo; // Move para a próxima variável
            if (var_atual != NULL) {
                printf(", ");
            }
        }
        printf("]");
        escopo_atual = escopo_atual->proximo; // Move para o próximo escopo
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
        sprintf(buffer, "%d", numero); // Converte o número para string
    }
    return buffer; // Retorna a string
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
        return "NUMERO"; // Retorna NUMERO se corresponder
    } else if (regex_match(str, cadeia_regex)) {
        return "CADEIA"; // Retorna CADEIA se corresponder
    } else {
        return "DESCONHECIDO"; // Retorna DESCONHECIDO se não corresponder
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

    return nova_str; // Retorna a nova string
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

    return nova_str; // Retorna a nova string
}

int linha_indice = 1; // Declaração da variável de contagem de linhas

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
    programa linha {
        linha_indice++; 
        //printf("[%d] ", linha_indice); imprimir_pilha();
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
        empilhar_escopo(); // Empilha um novo escopo
    }
    ;

linha_fim_bloco:
    BLOCO_FIM {
        desempilhar_escopo(); // Desempilha o escopo atual
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
            adicionar_variavel_cadeia("CADEIA", s1, $3.string); // Adiciona uma variável do tipo cadeia
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_cadeia("CADEIA", s1, $3.string); // Adiciona uma variável do tipo cadeia
            }
            else {
                printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
            }
        }
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string); 
        if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
            adicionar_variavel_cadeia("CADEIA", s1, ""); // Adiciona uma variável do tipo cadeia sem valor
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_cadeia("CADEIA", s1, ""); // Adiciona uma variável do tipo cadeia sem valor
            }
            else {
                printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
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
            adicionar_variavel_numero("NUMERO", s1, $3.number); // Adiciona uma variável do tipo número
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_numero("NUMERO", s1, $3.number); // Adiciona uma variável do tipo número
            }
            else {
                printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
            }
        }
    }
    | IDENTIFICADOR {
        char* s1 = remove_espacos($1.string); 
        if (verifica_variavel_existe_pilha(remove_espacos(s1)) == NULL) {
            adicionar_variavel_numero("NUMERO", s1, 0); // Adiciona uma variável do tipo número com valor 0
        }
        else {
            if (verifica_variavel_existe_escopo_atual(s1) == NULL){
                adicionar_variavel_numero("NUMERO", s1, 0); // Adiciona uma variável do tipo número com valor 0
            }
            else {
                printf("[%d] Erro: variável '%s' já declarada no escopo\n", linha_indice, s1);
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
                if (strcmp(tipo_expressao, "NUMERO") == 0) {
                    int expressao_number = atoi($3.string);
                    atualiza_variavel("NUMERO", s1, expressao_number, "");
                }
                else if (strcmp(tipo_expressao, "CADEIA") == 0){
                    char* nova_cadeia;
                    nova_cadeia = (char *)malloc((strlen($3.string) + 1) * sizeof(char));
                    strcpy(nova_cadeia, $3.string);
                    atualiza_variavel("CADEIA", s1, 0, nova_cadeia);
                    free(nova_cadeia);
                }
                else{
                    printf("[%d] Erro: tipo inválido\n", linha_indice);
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
    PRINT IDENTIFICADOR { 
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
    inicializar_pilha_de_escopos(); // Inicializa a pilha de escopos
    return yyparse();
}