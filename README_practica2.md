# Práctica 2 — Manejo avanzado de Flex (Sesión 3)

> Documento de apoyo para nosotros. **No va en el zip de entrega.**

## 1. De qué va la práctica (en corto)

**En esta práctica no hay que modificar ningún código.** A diferencia de la P3, no nos dan un programa para arreglar. Nos dan:

- el **enunciado** con dos ejercicios;
- **dos ejecutables ya hechos por el profesor** (`ej1_correcto` y `ej2_correcto`), sin su código.

**Lo que hay que hacer:** escribir desde cero dos programas en Flex (`ej1.l` y `ej2.l`) que hagan **lo mismo que los ejecutables del profesor**. Para comprobarlo se le pasa la misma entrada a los dos programas y la salida tiene que ser idéntica.

**El truco que se practica: las "condiciones de arranque" (estados).** En Flex se pueden definir estados con `%x NOMBRE` y saltar entre ellos con `BEGIN(NOMBRE)`. Cada patrón solo se aplica en los estados que tú digas. Por ejemplo:

- si estoy **dentro de un comentario**, una `{` no cuenta;
- si estoy **dentro del código de una acción**, una `{` sí cuenta.

El texto es el mismo, pero el significado cambia según el contexto. Para eso sirven los estados.

- Teoría: capítulo 9 del manual de Flex (`Prácticas/Herramientas y manuales/Manual flex 2.5.pdf`) y libro *flex & bison*, pp. 28–31.
- Enunciado: [Enunciado práctica 2.pdf](Enunciado%20práctica%202.pdf)
- Ejecutables de referencia: `Ejecutables correctos P2.zip`, extraídos en `correctos/` (`ej1_correcto`, `ej2_correcto`). Los nuestros deben dar **exactamente la misma salida**.

Hay dos ejercicios:

| Ejercicio | Fichero | Qué hace | Estado |
|---|---|---|---|
| 1 | `ej1.l` | Analiza un fichero `.l` y cuenta líneas de C y reglas | ✅ Hecho y verificado |
| 2 | `ej2.l` | Juego de semillas g/j: pone `1-` o `2-` delante de cada línea | ⏳ Pendiente |

---

## 2. Normas de entrega (comprobar todas)

- [ ] **Cabecera** en cada `.l` con los **NIAs y nombres** de los autores, como comentario en las primeras líneas.
- [ ] Código **documentado**, con comentarios.
- [ ] Compila y ejecuta correctamente en **lab000**.
- [ ] Zip llamado **`niaPr2.zip`** (con vuestro NIA).
- [ ] El zip contiene **solo**: la memoria en **PDF**, los fuentes **`.l`** y las pruebas **`.txt`**. **Sin subdirectorios.**
- [ ] La memoria incluye una **sección declarando el uso de herramientas de IA**.
- [ ] Para el ej2, la memoria **explica cómo se ha deducido la solución** (autómata, estados, expresiones regulares).
- [ ] Se sube en la tarea de Moodle (sección Prácticas de Laboratorio).
- [ ] Fecha tope: **el día anterior al comienzo de la Práctica 3**.

**NO meter en el zip:** `ej1.yy.c`, el ejecutable `ej1`, la carpeta `correctos/`, el zip de ejecutables, el enunciado ni este README.

---

## 3. Ejercicio 1 — `ej1.l` ✅

### Qué pide, explicado fácil

**Nos dan:** un fichero de Flex cualquiera (un `.l`, como los que escribimos nosotros), sin errores.

**Hay que hacer:** un programa que lea ese `.l` y diga **cuánto código C tiene y cuántas reglas**. Es un "contador" de ficheros Flex.

Un `.l` tiene 3 partes separadas por `%%`:

```
   ...declaraciones...       ← parte 1: aquí puede haber trozos de C entre %{ y %}
%%
   patrón   { acción en C }   ← parte 2: las reglas
%%
   código C (main, etc.)     ← parte 3
```

Y hay que sacar 4 números:

| Salida | Qué cuenta | Ejemplo |
|---|---|---|
| `C1` | Líneas de C metidas entre `%{` y `%}` en la parte 1 | `%{`↵`int a;`↵`%}` → 1 |
| `C2` | Líneas que ocupan las acciones `{ ... }` de las reglas (cada acción cuenta sus saltos de línea + 1) | `{ a++; }` → 1; `{ a++;`↵`b++; }` → 2 |
| `C3` | Líneas de la parte 3 (desde el segundo `%%`) | |
| `R` | Cuántas reglas hay | |

**Dónde está la dificultad:** dentro de una cadena `"..."` o de un comentario `/* ... */` o `// ...` puede haber llaves `{ }` o `%}` que **no hay que tener en cuenta**. Por ejemplo, en `{ printf("}}}"); }` la acción se cierra en la última `}`, no en las de dentro de la cadena. Por eso hacen falta estados: "estoy en una cadena", "estoy en un comentario", "estoy en una acción"…

Las reglas exactas del enunciado:

La entrada es un fichero de Flex correcto. Restricciones que el enunciado garantiza:

- los patrones no tienen espacios ni tabuladores y no ocupan varias líneas;
- las acciones van siempre entre `{` y `}`;
- en la sección de reglas, `{` y `}` solo aparecen en los patrones, delimitando acciones o como bloques de C dentro de las acciones;
- las cadenas van entre `"` y no contienen `\"`.

Dentro de cadenas y comentarios (`//…` y `/*…*/`) puede aparecer cualquier carácter (llaves, `%`, …), y **no debe contar**.

La salida tiene exactamente 4 líneas:

```
C1:<líneas (\n) dentro de los bloques %{ ... %} de la sección 1>
C2:<líneas dentro de las acciones de las reglas>
C3:<líneas de la sección 3>
R:<número de reglas>
```

- **C1**: número de `\n` entre `%{` y `%}`, ambos al inicio de línea. Puede haber varios bloques.
- **C2**: por cada acción, número de `\n` entre la `{` que la abre y la `}` que la cierra, **más uno**.
- **C3**: número de `\n` desde la línea del segundo `%%` (incluida) hasta el final.
- **R**: número de reglas.

### Cómo lo hemos resuelto (estados)

| Estado | Sección | Qué hace |
|---|---|---|
| `INITIAL` | 1 | Ignora todo. `^%{` → `BLOQUEC`; `^%%` → `REGLAS` |
| `BLOQUEC` (`%x`) | 1 | Cada `\n` suma 1 a C1; `^%}` → `INITIAL`. Un `%}` que no esté al inicio de línea (p. ej. en un comentario) no cierra el bloque |
| `REGLAS` (`%x`) | 2 | Patrón `^[^[:space:]]+[[:blank:]]+"{"`: una regla empieza al inicio de línea con un patrón sin blancos, seguido de blancos y de la `{` de la acción. Suma 1 a R, suma 1 a C2 (el "+1"), pone `nivel = 1` → `ACCION`. `^%%` → `CODIGO` |
| `ACCION` (`%x`) | 2 | `\n` suma 1 a C2; `{` hace `nivel++`; `}` hace `nivel--` y, si llega a 0, → `REGLAS`; `"` → `CADENA`; `//` → `COMLINEA`; `/*` → `COMMULTI` |
| `CADENA` (`%x`) | 2 | Ignora todo hasta la `"` de cierre (los `\n` sí suman a C2) |
| `COMLINEA` (`%x`) | 2 | Ignora hasta `\n` (que suma a C2) → `ACCION` |
| `COMMULTI` (`%x`) | 2 | Ignora hasta `*/` (los `\n` sí suman a C2) → `ACCION` |
| `CODIGO` (`%x`) | 3 | Cada `\n` suma 1 a C3 |

Las llaves del patrón (`{DIGITO}+`, `"aabb{"`) no se confunden con la acción porque el patrón se consume entero con `^[^[:space:]]+` antes de llegar a la `{` que va tras los blancos.

`main` acepta el fichero como argumento (`./ej1 fichero`) o por la entrada estándar (`./ej1 < fichero`).

### Cambios hechos durante el desarrollo

1. **C3.** Al principio contábamos la línea del `%%` como 1 y además su `\n`, lo que daba uno de más (5 en vez de 4 en el ejemplo). Comparando con `ej1_correcto` se vio que la referencia **solo cuenta los `\n`** desde el `%%` incluido. Ahora `^%%` en `REGLAS` solo cambia a `CODIGO`, y todo se cuenta allí. Consecuencias: sin salto de línea final se cuenta una línea menos, y un `%%` sin nada detrás da `C3:0`, igual que la referencia.
2. **Patrón de regla.** Al principio era `^[^ \t\n]+[ \t]+"{"`, que lleva **espacios dentro del patrón** e incumple la propia restricción del enunciado, así que `ej1.l` no era una entrada válida para sí mismo. Se cambió a `^[^[:space:]]+[[:blank:]]+"{"`. Ahora `ej1.l` se puede analizar a sí mismo y coincide con la referencia.

### Pruebas (todas coinciden con `ej1_correcto`)

| Fichero | Qué prueba | Salida |
|---|---|---|
| `prueba_ej1_1.txt` | Ejemplo del enunciado | `C1:6 C2:7 C3:4 R:3` |
| `prueba_ej1_2.txt` | Comentarios multilínea en bloques C, `%x`, llaves en cadenas y comentarios `//` y `/* */`, `if`/`for` anidados, `<ESTADO>` en patrones | = referencia |
| `prueba_ej1_3.txt` | Fichero mínimo sin sección 3 | = referencia |
| `prueba_ej1_4.txt` | Copia de `ej1.l` (el programa se analiza a sí mismo) | `C1:8 C2:26 C3:18 R:26` |

También se comprobaron, con ficheros temporales ya borrados: fichero sin `\n` final y un `%%` final sin nada detrás.

Comprobar que todo coincide con la referencia:

```bash
for f in prueba_ej1_*.txt; do diff <(./ej1 < $f) <(correctos/ej1_correcto < $f) > /dev/null && echo "$f OK" || echo "$f DIFF"; done
```

Compilar en lab000:

```bash
flex ej1.l && gcc lex.yy.c -o ej1 && ./ej1 < prueba_ej1_1.txt
```

### Pendiente del ej1

- [ ] Poner NIAs y nombres en la cabecera de `ej1.l` (ahora pone `NIA XXXXXX Nombre Apellidos`). Si después regeneráis `prueba_ej1_4.txt` copiando `ej1.l`, actualizad su salida en esta tabla.
- [ ] Probar la compilación en lab000.

---

## 4. Ejercicio 2 — `ej2.l` ⏳ (pendiente)

### Qué pide, explicado fácil

**Nos dan:** un fichero de texto donde cada línea es una fila de semillas, por ejemplo `ggjj` (g = garbanzo, j = judía).

**Hay que hacer:** un programa que, para cada línea, escriba delante `1-` si con esa fila inicial gana el jugador que empieza, o `2-` si gana el otro (jugando ambos lo mejor posible).

**La gracia:** no se simula el juego. Se averigua con autómatas (en JFlap) **qué forma tienen** las filas que ganan para el 1 y para el 2. Eso se convierte en dos expresiones regulares, y el programa Flex solo tiene que comprobar a cuál de las dos se ajusta cada línea. La memoria tiene que explicar cómo se ha llegado a esas expresiones.

**Las reglas del juego, en detalle:**

Hay dos jugadores, cada uno con 10 garbanzos (`g`) y 10 judías (`j`), y una hilera inicial `h0`. En cada turno:

1. el jugador añade una semilla suya a la derecha;
2. si puede señalar una semilla `x` tal que, desde el inicio hasta `x` (incluida), el número de `g` es ≡ 1 (mod 3), y desde `x` (incluida) hasta el final el número de `j` es par, puede elegir entre **repetir turno** o pasar.

Gana quien coloque antes todas sus semillas.

`ej2.l` lee líneas de `g`/`j` (puede haber líneas vacías, es decir `h0 = ε`) y escribe `1-` o `2-` delante de cada una, según quién tenga estrategia ganadora.

Ejemplo: `jjgj`→`1-`, `ε`→`1-`, `ggjj`→`2-`, `jjgg`→`2-`, `jjggj`→`1-`, `jgj`→`1-`.

### Cómo hay que hacerlo (según la ayuda del enunciado)

1. Definir L = { w = u₁ x u₂ : |u₁x|_g ≡ 1 (mod 3), |x u₂|_j par }, es decir, las hileras desde las que se puede repetir turno.
2. En **JFlap**: hacer un AFnD para L, pasarlo a AFD y **minimizarlo**.
3. Con los estados del AFD mínimo, razonar qué `h0` dan estrategia ganadora al jugador 1 y cuáles al 2.
4. Modificar el autómata (estados finales para el jugador 1 o para el 2) y obtener las **expresiones regulares** con JFlap.
5. Pasar las ER a **sintaxis Flex** (JFlap usa `+` para la unión y `λ` para la cadena vacía; en Flex son `|` y `?`/`*`).
6. `ej2.l`: patrones `^ER1\n` → `printf("1-%s", yytext)` y `^ER2\n` → `printf("2-%s", yytext)`. Ojo con la línea vacía y con la última línea si no termina en `\n`.
7. Comparar con `correctos/ej2_correcto` sobre muchas cadenas, por ejemplo todas las de longitud ≤ 10, generadas con un script.
8. Incluir en la memoria la deducción completa: AFnD, AFD mínimo (capturas de JFlap), razonamiento de la estrategia y ER.

---

## 5. Memoria (PDF) — qué debe incluir

- Portada: asignatura, práctica 2, NIAs y nombres.
- **Ej1**: explicación de las condiciones de arranque usadas (la tabla de estados de arriba), decisiones tomadas (cómo se cuenta C3, cómo se distingue el patrón de la acción) y pruebas con sus salidas.
- **Ej2**: deducción completa (autómatas, estados, estrategia, ER, paso a Flex) y pruebas.
- **Sección de uso de IA**: declarar que se ha usado un asistente de IA (Claude) para orientar y desarrollar/verificar el código, y en qué partes.

---

## 6. Estado de la carpeta

| Fichero | ¿Va al zip? | Qué es |
|---|---|---|
| `ej1.l` | ✅ | Fuente del ejercicio 1 |
| `prueba_ej1_1.txt` … `prueba_ej1_4.txt` | ✅ | Pruebas del ejercicio 1 |
| `ej2.l`, `prueba_ej2_*.txt` | ✅ (cuando estén) | Ejercicio 2 |
| memoria `.pdf` | ✅ (cuando esté) | Memoria |
| `ej1.yy.c`, `ej1` | ❌ | Generados al compilar |
| `correctos/`, `Ejecutables correctos P2.zip` | ❌ | Referencia del profesor |
| `Enunciado práctica 2.pdf`, `README_practica2.md` | ❌ | Apoyo |

Crear el zip al final, sustituyendo `NIA` y el nombre de la memoria:

```bash
zip NIAPr2.zip ej1.l ej2.l prueba_ej1_*.txt prueba_ej2_*.txt memoria.pdf
```
