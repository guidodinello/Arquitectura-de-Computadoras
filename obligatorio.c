#include <stdio.h>
/*
> gcc obligatorio.c -o obligatorio
> ./obligatorio
*/

#define stack_size 31
#define PUERTO_SALIDA_DEFECTO 1
#define PUERTO_LOG_DEFECTO 2
#define ENTRADA 3

/* Esta seccion es con fines de debugging, refiere al testing y la impresion de los puertos */
typedef struct puertos {
    char* nombre;
    short direccion;
    short cant_datos;
    short info[255];
} puerto;
puerto arregloPuertoSalida = (puerto){ .nombre = "Salida", .direccion = PUERTO_SALIDA_DEFECTO, .cant_datos = 0, .info = {0} };
puerto arregloPuertoLog = (puerto){ .nombre = "Bitacora", .direccion = PUERTO_LOG_DEFECTO, .cant_datos = 0, .info = {0} }; 
puerto* puertos[2] = {&arregloPuertoLog, &arregloPuertoSalida};
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
    if (puerto == arregloPuertoLog.direccion) {
        arregloPuertoLog.info[arregloPuertoLog.cant_datos] = dato;
        arregloPuertoLog.cant_datos++;
    } else if (puerto == arregloPuertoSalida.direccion) {
        arregloPuertoSalida.info[arregloPuertoSalida.cant_datos] = dato;
        arregloPuertoSalida.cant_datos++;
    } else {
        printf("Error: Puerto %hu no existe.\n", puerto);
    }
}
short entrada[255] = {
    //1,1, 1,2, 1,3, 1,4, 1,5, 1,1, 1,9, 1,8, 1,-1400, 1,10, 1,11, 1,12, 1,13, 11, 4, 12, 4, 13, 4, 14, 4, 15, 4, 16, 4, 17, 4, 18, 4, 7, 4, 19, 4, 10, 4, 8, 4, 6, 5, 254, 255 
    1, 1, 8, 4, 1, 2, 8, 4, 1, -1, 8, 4, 1, -2, 8, 4, 255
};
short entrada_index = 0;
short IN(short puerto) {
    short aux = entrada[entrada_index];
    entrada_index++;
    return aux;
}
/* */


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
    short puertoSalida = PUERTO_SALIDA_DEFECTO;
    short puertoLog = PUERTO_LOG_DEFECTO;

    while (1) {
        comando = IN(ENTRADA);
        OUT(puertoLog, 0);
        OUT(puertoLog, comando);
        switch (comando) {
            case 1: { // NUM(numero)
                short numero;
                numero = IN(ENTRADA);
                OUT(puertoLog, numero);

                if (stack.tope == stack_size) {
                    // codigo de error por desborde
                    OUT(puertoLog, 4);
                } else {
                    push(numero);
                    // codigo exito
                    OUT(puertoLog, 16);
                }
                break;
            } case 2: { // PORT(puerto)
                short parametro = IN(ENTRADA);
                OUT(puertoLog, parametro);
                puertoSalida = parametro;

                // debugging
                arregloPuertoSalida.direccion = parametro;

                OUT(puertoLog, 16);
                break;
            } case 3: { // LOG(puerto)
                short parametro = IN(ENTRADA);
                OUT(puertoLog, parametro);
                puertoLog = parametro;

                // debugging
                arregloPuertoLog.direccion = parametro;

                OUT(puertoLog, 16);
                break;
            } case 4: { // TOP()
                if (stack.tope != 0) {
                    OUT(puertoSalida, stack.data[stack.tope-1]);
                    OUT(puertoLog, 16);
                } else {
                    // codigo falta operando en la pila
                    OUT(puertoLog, 8);
                }
                break;
            } case 5: { // DUMP()
                short index = stack.tope;
                while (index > 0) {
                    index--;
                    OUT(puertoSalida, stack.data[index]);
                }
                OUT(puertoLog, 16);
                break;
            } case 6: { // DUP()
                if (stack.tope == 31) {
                    // codigo de error por desborde
                    OUT(puertoLog, 4);
                } else if (stack.tope == 0) {
                    // codigo de error por falta de operandos
                    OUT(puertoLog, 8);
                } else {
                    push(stack.data[stack.tope]);
                    OUT(puertoLog, 16);
                }
                break;
            } case 7: { // SWAP()
                if (stack.tope >= 2) {
                    short tope = pop();
                    short topeMenosUno = pop();
                    push(tope);
                    push(topeMenosUno);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 8: { // NEG()
                if (stack.tope != 0) {
                    short tope = pop();
                    push(-tope);
                    OUT(puertoLog, 16);
                } else {
                    OUT(puertoLog, 8);
                }
                break;
            } case 9: { // FACT()
                if (stack.tope != 0) {
                    res = pop();
                    push( fact(res) );
                    OUT(puertoLog, 16);
                } else {
                    OUT(puertoLog, 8);
                }
                break;
            } case 10: { // SUM()
                short acum = 0;
                while (stack.tope > 0) acum += pop();
                push(acum);
                OUT(puertoLog, 16);
                break;
            } case 11: { // ADD()
                if (stack.tope >= 2) {
                    n = pop();  
                    res = pop() + n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop(); // si solo hay un operando la pila queda vacia
                    OUT(puertoLog, 8);
                }
                break;
            } case 12: { // SUBSTRACT()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() - n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 13: { // MULTIPLY()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() * n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 14: { // DIVIDE()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() / n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 15: { // MOD()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() % n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 16: { // AND()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() & n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 17: { // OR()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() | n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 18: { // LSHIFT()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() << n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 19: { // RSHIFT()
                if (stack.tope >= 2) {
                    n = pop();
                    res = pop() >> n;
                    push(res);
                    OUT(puertoLog, 16);
                } else {
                    if (stack.tope == 1) 
                        pop();
                    OUT(puertoLog, 8);
                }
                break;
            } case 254: {   // CLEAR()
                stack.tope = 0;
                OUT(puertoLog, 16);
                break;
            } case 255: {  // HALT()
                OUT(puertoLog, 16);

                // debugging
                imprimirPuertos();
                
                while (1) {};
                break;
            } default: {
                OUT(puertoLog, 2); // código 2 : comando inválido
            }
        }
    }

    return 0;
}