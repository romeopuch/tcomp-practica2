/*
 * Practica 2 - Ejercicio 2
 * NIA: 926247   Nombre: Javier Sánchez
 * NIA: 925301   Nombre: Romeo Puch
 */
%option noyywrap

P2  j*g(jggj(jj)*g|(g|jgj)(jj)*(g|jgj)(jj)*g)*(jggj(jj)*|(g|jgj)(jj)*((g|jgj)(jj)*)?)?

%%

^\n             { printf("1-\n"); }
^{P2}           { printf("2-%s", yytext); }
^[gj]+          { printf("1-%s", yytext); }
\n              { printf("\n"); }

%%

int main() {
    yylex();
    return 0;
}
