%{
#include <stdio.h>
#include "y.tab.h"
%}

%%

[ \t]*BLOCO[ \t]*_[a-zA-Z0-9][a-zA-Z0-9]*_     { return BLOCO_INICIO; }
[ \t]*FIM[ \t]*_[a-zA-Z0-9][a-zA-Z0-9]*_     { return BLOCO_FIM; }
[ \t]*NUMERO[ \t]*          { return TIPO_NUMERO; }
[ \t]*CADEIA[ \t]*          { return TIPO_CADEIA; }
[ \t]*PRINT[ \t]*           { return PRINT; }
[ \t]*[a-zA-Z][a-zA-Z0-9]*[ \t]*   { yylval.string = strdup(yytext); return IDENTIFICADOR; }
[ \t]*[0-9]+[ \t]*          { yylval.number = atoi(yytext); return NUMERO; }
[ \t]*\"[^\"]*\"[ \t]*        { yylval.string = strdup(yytext); return CADEIA; }
=                           { return '='; }
;                           { return ';'; }
,                           { return ','; }
\+                          { return '+'; }
\n                          { /* Ignorar novas linhas */ }
[ \t]+                      { /* Ignorar espaços e tabulações */ }
.                           { printf("Desconhecido: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}
