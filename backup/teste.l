%{
#include <stdio.h>
#include "y.tab.h"
%}

%%

[ \t]*BLOCO[ \t]*_[a-zA-Z_][a-zA-Z0-9_]*_[ \t]*      { return BLOCO_INICIO; }
[ \t]*FIM[ \t]*_[a-zA-Z_][a-zA-Z0-9_]*_[ \t]*        { return BLOCO_FIM; }
[ \t]*NUMERO[ \t]*          { return TIPO_NUMERO; }
[ \t]*CADEIA[ \t]*          { return TIPO_CADEIA; }
[ \t]*PRINT[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]* { return PRINT; }
[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*   { yylval.sval = strdup(yytext); return IDENTIFICADOR; }
[ \t]*[+-]?\d+(\.\d+)?[ \t]*         { yylval.ival = atoi(yytext); return NUMERO; }
[ \t]*\"[^\"]*\"[ \t]*                  { yylval.sval = strdup(yytext); return CADEIA; }
=                           { return '='; }
;                           { return ';'; }
,                           { return ','; }
\+                          { return '+'; }
\n                          { /* Ignorar novas linhas */ }
[ \t]+                       { /* Ignorar espaços e tabulações */ }
.                           { printf("Caractere desconhecido: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}
