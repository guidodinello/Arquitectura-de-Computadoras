#include <stdio.h>
/*
> gcc obligatorio.c -o obligatorio
> ./obligatorio
*/

/* Esta seccion es con fines de debugging, refiere al testing y la impresion de los puertos */
typedef struct puertos {
    char* nombre;
    short direccion;
    short cant_datos;
    short info[255];
} puerto;
puerto puertoSalida = (puerto){ .nombre = "Salida", .direccion = 2, .cant_datos = 0, .info = {0} };
puerto puertoLog = (puerto){ .nombre = "Bitacora", .direccion = 3, .cant_datos = 0, .info = {0} }; 
puerto* puertos[2] = {&puertoLog, &puertoSalida};
void imprimirPuertos() {
    int cant_puertos = sizeof(puertos) / sizeof(puerto*);
    for (int i=0; i < cant_puertos; i++) {
        printf("Puerto %s (%hu) : ", puertos[i]->nombre, puertos[i]->direccion);
        for(int j = 0; j < puertos[i]->cant_datos; j++)
            printf("%hu, ", puertos[i]->info[j]);
        printf(".\n");
    }
    printf("\n");
}
void OUT(short puerto, short dato) {
    if (puerto == puertoLog.direccion) {
        puertoLog.info[puertoLog.cant_datos] = dato;
        puertoLog.cant_datos++;
    } else if (puerto == puertoSalida.direccion) {
        puertoSalida.info[puertoSalida.cant_datos] = dato;
        puertoSalida.cant_datos++;
    }
}
short entrada[255] = {
    //2, 15, 1, 14, 1, 3, 1, 4, 5, 11, 14, 1, 1, 11, 4, 255
    1, 1, 1, 2, 1, 3, 1, 4, 1, 5, 1, 6, 1, 7, 1, 8, 1, 9, 1, 10, 1, 11, 1, 12, 1, 13, 1, 14, 1, 15, 1, 16, 1, 17, 1, 18, 1, 19, 1, 20, 1, 21, 1, 22, 1, 23, 1, 24, 1, 25, 1, 26, 1, 27, 1, 28, 1, 29, 1, 30, 1, 31, 1, 32,  5, 255
};
short entrada_index = 0;
short IN(short puerto) {
    short aux = entrada[entrada_index];
    entrada_index++;
    return aux;
}
/* */

// ARREGLAR PORT Y LOG, ESTOY ASIGNANDO A LO QUE DEBERIA SER UNA CONSTANTE, LOS DEFECTO SON CONSTANTES

#define stack_size 31
#define ENTRADA 1

short PUERTO_SALIDA_DEFECTO = 2;
short PUERTO_LOG_DEFECTO = 3;

struct arrayConTope {
    short tope;
    short data[stack_size]; 
} stack;

/* estas funciones se utilizaran como interfaz para el manejo de la pila */
void push(short a) {
    stack.data[stack.tope] = a;
    stack.tope ++;
}
short pop() {
    stack.tope --;
    return stack.data[stack.tope];
}
/*          */


short fact(short n) { 
    if (n == 0)
        return 1;
    else 
        return n * fact(n-1); 
} 

int main() {
    short comando;
    short res, n;

    while (1) {
        comando = IN(ENTRADA);
        OUT(PUERTO_LOG_DEFECTO, 0);
        OUT(PUERTO_LOG_DEFECTO, comando);
        switch (comando) {
            case 1: { // NUM(numero)
                short numero;
                numero = IN(ENTRADA);
                OUT(PUERTO_LOG_DEFECTO, numero);

                if (stack.tope == stack_size) {
                    // codigo de error por desborde
                    OUT(PUERTO_LOG_DEFECTO, 4);
                } else {
                    push(numero);
                    // codigo exito
                    OUT(PUERTO_LOG_DEFECTO, 16);
                }
                break;
            } case 2: { // PORT(puerto)
                short parametro = IN(ENTRADA);
                OUT(PUERTO_LOG_DEFECTO, parametro);
                PUERTO_SALIDA_DEFECTO = parametro;

                // debugging
                puertoSalida.direccion = parametro;

                OUT(PUERTO_LOG_DEFECTO, 16);
                break;
            } case 3: { // LOG(puerto)
                short parametro = IN(ENTRADA);
                OUT(PUERTO_LOG_DEFECTO, parametro);
                PUERTO_LOG_DEFECTO = parametro;

                // debugging
                puertoLog.direccion = parametro;

                OUT(PUERTO_LOG_DEFECTO, 16);
                break;
            } case 4: { // TOP()
                if (stack.tope != 0) {
                    OUT(PUERTO_SALIDA_DEFECTO, stack.data[stack.tope-1]);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    // codigo falta operando en la pila
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 5: { // DUMP()
                short index = stack.tope;
                while (index > 0) {
                    index--;
                    OUT(PUERTO_SALIDA_DEFECTO, stack.data[index]);
                }
                OUT(PUERTO_LOG_DEFECTO, 16);
                break;
            } case 6: { // DUP()
                if (stack.tope == 31) {
                    // codigo de error por desborde
                    OUT(PUERTO_LOG_DEFECTO, 4);
                } else if (stack.tope == 0) {
                    // codigo de error por falta de operandos
                    OUT(PUERTO_LOG_DEFECTO, 8);
                } else {
                    push(stack.data[stack.tope]);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                }
                break;
            } case 7: { // SWAP()
                if (stack.tope >= 2) {
                    short tope = pop();
                    short topeMenosUno = pop();
                    push(tope);
                    push(topeMenosUno);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 8: { // NEG()
                if (stack.tope != 0) {
                    short tope = pop();
                    push(~tope);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 9: { // FACT()
                if (stack.tope != 0) {
                    res = pop();
                    push( fact(res) );
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 10: { // SUM()
                short acum = 0;
                while (stack.tope > 0) acum += pop();
                push(acum);
                OUT(PUERTO_LOG_DEFECTO, 16);
                break;
            } case 11: { // ADD()
                if (stack.tope >= 2) {
                    n = pop();  
                    res = pop() + n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop(); // si solo hay un operando la pila queda vacia
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 12: { // SUBSTRACT()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() - n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 13: { // MULTIPLY()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() * n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 14: { // DIVIDE()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() / n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 15: { // MOD()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() % n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 16: { // AND()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() & n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 17: { // OR()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() | n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 18: { // LSHIFT()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() << n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 19: { // RSHIFT()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() >> n;
                    push(res);
                    OUT(PUERTO_LOG_DEFECTO, 16);
                } else {
                    if (stack.tope == 1) 
                        n = pop();
                    OUT(PUERTO_LOG_DEFECTO, 8);
                }
                break;
            } case 254: {   // CLEAR()
                stack.tope = 0;
                OUT(PUERTO_LOG_DEFECTO, 16);
                break;
            } case 255: {  // HALT()
                OUT(PUERTO_LOG_DEFECTO, 16);

                // debugging
                imprimirPuertos();
                
                while (1) {};
                break;
            } default: {
                OUT(PUERTO_LOG_DEFECTO, 2); // código 2 : comando inválido
            }
        }
    }

    return 0;
}