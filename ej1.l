/*
 * Práctica 2 - Teoría de la Computación - Ejercicio 1
 * Autores: NIA XXXXXX  Nombre Apellidos
 *          NIA XXXXXX  Nombre Apellidos
 *
 * Analiza un fichero fuente de Flex y muestra:
 *   C1: líneas dentro de los bloques %{ ... %} de la sección de declaraciones
 *   C2: líneas dentro de las acciones de las reglas
 *   C3: líneas de la sección de código (incluida la línea del segundo %%)
 *   R:  número de reglas
 */

%{
#include <stdio.h>

int c1 = 0;     /* líneas en bloques de C de la sección 1 */
int c2 = 0;     /* líneas en acciones de la sección 2 */
int c3 = 0;     /* líneas de la sección 3 */
int r = 0;      /* número de reglas */
int nivel = 0;  /* profundidad de llaves dentro de una acción */
%}

/* Sección 1 */
%x BLOQUEC
/* Sección 2 */
%x REGLAS ACCION CADENA COMLINEA COMMULTI
/* Sección 3 */
%x CODIGO

%%

 /* ---------- Sección de declaraciones ---------- */
^"%{"               { BEGIN(BLOQUEC); }
^"%%"               { BEGIN(REGLAS); }
.|\n                { }

 /* Bloque de C: solo lo cierra un %} al inicio de línea */
<BLOQUEC>^"%}"      { BEGIN(INITIAL); }
<BLOQUEC>\n         { c1++; }
<BLOQUEC>.          { }

 /* ---------- Sección de reglas ---------- */
 /* Su salto de línea se cuenta ya en CODIGO */
<REGLAS>^"%%"       { BEGIN(CODIGO); }
 /* Patrón sin blancos al inicio de línea, blancos y la llave que abre la acción */
<REGLAS>^[^[:space:]]+[[:blank:]]+"{"  { r++; c2++; nivel = 1; BEGIN(ACCION); }
<REGLAS>.|\n        { }

 /* Acción: se cuentan saltos de línea y se siguen las llaves anidadas */
<ACCION>\n          { c2++; }
<ACCION>"{"         { nivel++; }
<ACCION>"}"         { if (--nivel == 0) BEGIN(REGLAS); }
<ACCION>\"          { BEGIN(CADENA); }
<ACCION>"//"        { BEGIN(COMLINEA); }
<ACCION>"/*"        { BEGIN(COMMULTI); }
<ACCION>.           { }

 /* Dentro de cadenas y comentarios las llaves no cuentan */
<CADENA>\"          { BEGIN(ACCION); }
<CADENA>\n          { c2++; }
<CADENA>.           { }

<COMLINEA>\n        { c2++; BEGIN(ACCION); }
<COMLINEA>.         { }

<COMMULTI>"*/"      { BEGIN(ACCION); }
<COMMULTI>\n        { c2++; }
<COMMULTI>.         { }

 /* ---------- Sección de código ---------- */
<CODIGO>\n          { c3++; }
<CODIGO>.           { }

%%

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            perror(argv[1]);
            return 1;
        }
    }
    yylex();
    printf("C1:%d\nC2:%d\nC3:%d\nR:%d\n", c1, c2, c3, r);
    return 0;
}

int yywrap(void) {
    return 1;
}
