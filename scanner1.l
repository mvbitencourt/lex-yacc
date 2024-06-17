%{
#include <stdio.h>
#include "y.tab.h"
%}

%%
begin   { return BEGIN; }
hello   { return HELLO; }
thanks  { return THANKS; }
end     { return END; }
.       { /* ignorar qualquer outro caractere */ }
%%