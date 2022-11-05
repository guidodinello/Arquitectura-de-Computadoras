.data
#define DS 100h

CODIGO_EXITO EQU 16
CODIGO_FALTA_OPERANDOS EQU 8
CODIGO_DESBORDAMIENTO EQU 4
CODIGO_COMANDO_INVALIDO EQU 2
CODIGO_NUEVO_COMANDO EQU 0

; ver si deberia en vez de in ax, ENTRADA
; hacer mov registro, ENTRADA
; luego in ax, registro

; las aritmeticas tienen todas la misma estructura
; ver si se puede factorizar y que solo se distingan en la llamada a la operacion
; jmp estructura_aritmeticas
;	... add/sub/imul/ ...

ENTRADA EQU 10
PUERTO_SALIDA_DEFECTO EQU 1
PUERTO_LOG_DEFECTO EQU 2
STACK_SIZE EQU 31

stack DW DUP(STACK_SIZE) 0
tope dw 0  						; aca seria mas correcto usar un db, pero no es necesario

DOBLE_STACK_SIZE EQU STACK_SIZE*2	; servira para chequear si la pila esta llena

puertoLog dw PUERTO_LOG_DEFECTO
puertoSalida dw PUERTO_SALIDA_DEFECTO

.code
	jmp main

; recibe el parametro en el registro AX
pushStack proc
	push bx
	push di						; preservamos el valor de di
	mov di, [tope]	
	mov bx, offset stack
	mov [bx+di],ax 				; stack[tope] = ax
	add word ptr [tope], 2
	pop di
	pop bx
	ret
pushStack endp

; retorna el resultado en el registro BX
popStack proc
	push di
	sub word ptr [tope], 2	; tope --;
	mov di, [tope]
	mov bx, offset stack
	mov bx, [bx+di]			; bx = stack[tope]
	pop di
	ret
popStack endp

; recibe el parametro en el registro AX y retorna el resultado en BX
factorial proc
	cmp ax, 0			; n==0 ?
	je paso_base		; return 1
	dec ax				; n' = n-1
	call factorial		; ax = factorial(n')
	inc ax
	mov cx, ax
	mul bx				; dx::ax = ax * bx
	mov bx, ax
	mov ax, cx
	jmp fin_factorial	; return n * factorial(n')
paso_base:
	mov bx, 1			
fin_factorial:
	ret
factorial endp

NUM:
	in ax, ENTRADA							; leo parametro
	mov dx, [puertoLog]						;
	out dx, ax								; out en bitacora del parametro leido
	cmp word ptr [tope], DOBLE_STACK_SIZE	; if (tope == stack_size)
	jne exito_num							
	mov ax, CODIGO_DESBORDAMIENTO
	out dx, ax								; out 4 : desbordamiento de la pila
	jmp fin_num
exito_num:
	call pushStack							; se agrega el parametro al stack
	mov ax, CODIGO_EXITO
	out dx, ax								; out 16 : proceso exitoso
fin_num:
	jmp main

PORT:
	push ax
	push dx						; preservo valores de registros
	in ax, ENTRADA				; parametro = IN(ENTRADA)
	mov dx, [puertoLog]			; dx = puertoLog
	out dx, ax					; out en bitacora del parametro leido
	mov [puertoSalida], ax		; puertoSalida = parametro
	mov ax, CODIGO_EXITO		; ax = 16
	out dx, ax 					; out 16 : proceso exitoso
	pop dx
	pop ax
	jmp main

LOG:
	push ax
	push dx						; preservo valores de registros
	in ax, ENTRADA				; parametro = IN(ENTRADA)
	mov dx, [puertoLog]			; dx = puertoLog
	out dx, ax					; out en bitacora del parametro leido
	mov [puertoLog], ax			; puertoLog = parametro
	mov ax, CODIGO_EXITO		; ax = 16
	mov dx, [puertoLog] 		; dx = nuevo puerto log
	out dx, ax 					; out 16 : proceso exitoso
	pop dx
	pop ax
	jmp main

TOP:
	push ax
	push dx
	cmp word ptr [tope], 0			; if (tope == 0)
	jne exito_top
	mov dx, [puertoLog]				; dx = puertoLog
	mov ax, CODIGO_FALTA_OPERANDOS	; ax = 8
	out dx, ax						; out 8 : falta de operandos en la pila
	jmp fin_top
exito_top:							; else
	push di
	push bx
	mov di, [tope]					; di = tope
	sub di, 2						; di = tope - 1
	mov bx, offset stack
	mov ax, [bx+di]					; ax = stack[tope]
	mov dx, [puertoSalida]			; dx = puertoSalida
	out dx, ax						; out en salida del tope de la pila
	mov ax, CODIGO_EXITO			; ax = 16
	mov dx, [puertoLog] 			; dx = puertoLog
	out dx, ax						; out 16 : proceso exitoso		
	pop bx
	pop di			
fin_top:
	push dx
	push ax
	jmp main

DUMP:
	mov di, [tope]
	mov bx, offset stack
	mov dx, [puertoSalida]			; dx = puertoSalida, hacer esta asignacion aca evita estar repitiendola
									; innecesariamente en cada iteracion del while
while_dump:
	cmp di, 0
	je fin_dump						; index > 0 ?
	sub di, 2	
	mov ax, [bx+di]					; ax = stack[tope - 1]
	out dx, ax						; out en salida del tope de la pila
	jmp while_dump
fin_dump:							; index <= 0
	mov ax, CODIGO_EXITO			; ax = 16
	mov dx, [puertoLog] 			; dx = puertoLog
	out dx, ax						; out 16 : proceso exitoso		
	jmp main

_DUP:
	push ax									
	push dx
	mov dx, [puertoLog]						; dx = puertoLog
	cmp word ptr [tope], DOBLE_STACK_SIZE	; if (tope == stack_size)
	je pila_llena_dup
	cmp word ptr [tope], 0					; if (tope == 0)
	je pila_vacia_dup	
	call popStack							; bx = stack[tope]
	mov ax, bx								; ax = bx
	call pushStack							; push(ax)
	call pushStack							; push(ax)
	mov ax, CODIGO_EXITO
	out dx, ax								; out 16 : proceso exitoso
	jmp fin_dup
pila_vacia_dup:
	mov ax, CODIGO_FALTA_OPERANDOS			
	out dx, ax								; out 8 : falta de operandos en la pila
	jmp fin_dup
pila_llena_dup:
	mov ax, CODIGO_DESBORDAMIENTO			
	out dx, ax								; out 4 : desbordamiento de la pila
fin_dup:
	pop dx
	pop ax
	jmp main

SWAP:
	push dx
	push ax
	mov dx, [puertoLog]
	cmp word ptr [tope], 4
	jge dos_o_mas_swap
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_swap
	jmp fin_swap
un_elemento_swap:
	call popStack			; vacia la pila
	jmp fin_swap
dos_o_mas_swap:
	push bx
	push cx
	call popStack
	mov cx, bx			; cx = valor que habia en el tope del stack
	call popStack		; bx = valor que habia debajo del tope en el stack
	mov ax, cx 
	call pushStack		; push(cx) = push(tope)
	mov ax, bx
	call pushStack		; push(bx) = push(topeMenosUno)
	mov ax, CODIGO_EXITO
	out dx, ax
	pop cx
	pop bx
fin_swap:
	pop ax
	pop dx
	jmp main

_NEG:
	push ax
	push dx
	mov dx, [puertoLog]				; dx = puertoLog
	cmp word ptr [tope], 0			; if (tope == 0)
	jne exito_neg
	mov ax, CODIGO_FALTA_OPERANDOS	; ax = 8
	out dx, ax						; out 8 : falta de operandos en la pila
	jmp fin_neg
exito_neg:							; else
	push bx
	call popStack					; bx = stack[tope]
	neg bx							; 
	mov ax, bx						; 
	call pushStack					; push(~tope)
	mov ax, CODIGO_EXITO			; ax = 16
	out dx, ax						; out 16 : proceso exitoso		
	pop bx			
fin_neg:
	push dx
	push ax
	jmp main

FACT:
	push ax
	push dx
	push cx
	mov dx, [puertoLog]				; dx = puertoLog
	cmp word ptr [tope], 0			; if (tope == 0)
	jne exito_fact
	mov ax, CODIGO_FALTA_OPERANDOS	; ax = 8
	out dx, ax						; out 8 : falta de operandos en la pila
	jmp fin_fact
exito_fact:
	push bx
	call popStack			; bx = stack[tope]
	mov ax, bx				; ax = bx
	call factorial			; bx = fact(ax)
	mov ax, bx
	call pushStack			; stack[tope] = bx
	mov dx, [puertoLog]		; el factorial modifica a dx
	mov ax, CODIGO_EXITO	; ax = 16
	out dx, ax				; out 16 : operacion exitosa
	pop bx
fin_fact:
	pop cx
	pop dx
	pop ax
	jmp main

SUM:
	push ax
	push bx
	push dx
	xor ax, ax					; acum = 0
while_sum:
	cmp word ptr [tope], 0
	je fin_sum					; tope > 0 ?
	call popStack				; bx = pop()
	add ax, bx					; ax += bx
	jmp while_sum
fin_sum:						; index <= 0
	call pushStack
	mov ax, CODIGO_EXITO		; ax = 16
	mov dx, [puertoLog] 		; dx = puertoLog
	out dx, ax					; out 16 : proceso exitoso		
	pop dx
	pop bx
	pop ax
	jmp main

_ADD:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_add
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_add
	jmp fin_add
un_elemento_add:
	call popStack			; vacia la pila
	jmp fin_add
exito_add:
	call popStack	 
	mov cx, bx 				; cx operando derecho
	call popStack			; bx operando izquierdo
	add bx, cx				; bx = bx + cx
	mov ax, bx
	call pushStack			; pushea el resultado de la suma
	mov ax, CODIGO_EXITO
	out dx, ax
fin_add:
	jmp main

SUBSTRACT:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_substract
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_substract
	jmp fin_substract
un_elemento_substract:
	call popStack			; vacia la pila
	jmp fin_substract
exito_substract:
	call popStack	 
	mov cx, bx 				; cx operando derecho
	call popStack			; bx operando izquierdo
	sub bx, cx				; bx = bx - cx
	mov ax, bx
	call pushStack			; pushea el resultado de la resta
	mov ax, CODIGO_EXITO
	out dx, ax
fin_substract:
	jmp main

MULTIPLY:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_multiply
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_multiply
	jmp fin_multiply
un_elemento_multiply:
	call popStack			; vacia la pila
	jmp fin_add
exito_multiply:
	xor dx, dx				; ES NECESARIO? imul lo sobreescribe de todas formas
	call popStack
	mov cx, bx				; cx operando derecho
	call popStack
	mov ax, bx				; ax operando izquierdo
	imul cx					; dx::ax = ax * cx
	call pushStack			; pushea el resultado de la suma (ax)
	mov dx, [puertoLog]
	mov ax, CODIGO_EXITO
	out dx, ax
fin_multiply:
	jmp main

DIVIDE:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_divide
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_divide
	jmp fin_divide
un_elemento_divide:
	call popStack			; vacia la pila
	jmp fin_divide
exito_divide:
	call popStack	 
	mov cx, bx 				; cx operando derecho
	call popStack			
	mov ax, bx				; ax operando izquierdo
							; quiero ax/cx e idiv hace ax = dx::ax div op1
	cmp ax, 0
	jl dividendo_negativo
	xor dx, dx			; si el dividendo es positivo cargo 0 en dx
	jmp dividir
dividendo_negativo:
	mov dx, 0xffff		; si el dividendo es negativo cargo 0xffff en dx
dividir:
	idiv cx				; en ax queda el resultado de la division entera
	call pushStack		; pushea ax
	mov ax, CODIGO_EXITO
	mov dx, [puertoLog]
	out dx, ax
fin_divide:
	jmp main

MOD:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_mod
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_mod
	jmp fin_mod
un_elemento_mod:
	call popStack			; vacia la pila
	jmp fin_mod
exito_mod:
	call popStack
	mov cx, bx 			; cx operando derecho
	call popStack	
	mov ax, bx			; ax operando derecho
	cmp ax, 0
	jl modulo_negativo
	xor dx, dx			; si el dividendo es positivo cargo 0 en dx
	jmp modulo
modulo_negativo:
	mov dx, 0xffff		; si el dividendo es negativo cargo 0xffff en dx
modulo:
	idiv cx
push_resultado_mod:
	mov ax, dx
	call pushStack		; pushea ax
	mov ax, CODIGO_EXITO
	mov dx, [puertoLog]
	out dx, ax
fin_mod:
	jmp main

_AND:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_and
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_and
	jmp fin_and
un_elemento_and:
	call popStack			; vacia la pila
	jmp fin_and
exito_and:
	call popStack	 
	mov cx, bx 				; cx operando derecho
	call popStack			; bx operando izquierdo
	and bx, cx
	mov ax, bx
	call pushStack			; pushea el resultado
	mov ax, CODIGO_EXITO
	out dx, ax
fin_and:
	jmp main

_OR:
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_or
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_or
	jmp fin_or
un_elemento_or:
	call popStack			; vacia la pila
	jmp fin_or
exito_or:
	call popStack
	mov cx, bx 				; cx operando derecho
	call popStack			; bx operando izquierdo
	or bx, cx
	mov ax, bx
	call pushStack			; pushea el resultado
	mov ax, CODIGO_EXITO
	out dx, ax
fin_or:
	jmp main

LSHIFT:		; REVISAR
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_lshift
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_lshift
	jmp fin_lshift
un_elemento_lshift:
	call popStack			; vacia la pila
	jmp fin_lshift
exito_lshift:
	call popStack	; 
	mov cx, bx 		; cx operando derecho
	call popStack	; bx operando izquierdo
	cmp cx, 16		; si shifteamos 16 lugares o mas el resultado, debe ser 0
	jge lshift_mayor_a_16	
	sal bx, cl		; bx = bx << cx (conservando el signo)
	mov ax, bx
	jmp push_resultado_lshift
lshift_mayor_a_16:
	mov ax, 0		; shiftear 16 o mas pos un num es dejarlo en 0
push_resultado_lshift:
	call pushStack	; pushea el resultado de la suma
	mov ax, CODIGO_EXITO
	out dx, ax
fin_lshift:
	jmp main

RSHIFT:		;REVISAR
	mov dx, [puertoLog]
	cmp word ptr [tope], 4	; hay dos o mas elementos
	jge exito_rshift
	mov ax, CODIGO_FALTA_OPERANDOS
	out dx, ax
	cmp word ptr [tope], 2  ; hay un elemento
	jge un_elemento_rshift
	jmp fin_rshift
un_elemento_rshift:
	call popStack			; vacia la pila
	jmp fin_rshift
exito_rshift:
	call popStack	; 
	mov cx, bx 		; cx operando derecho
	call popStack	; bx operando izquierdo
	cmp cx, 16		; si shifteamos 16 o mas lugares el resultado, debe ser -1 si b<0 o 0 si b>=0 
	jge rshift_mayor_a_16	
	sar bx, cl		; bx = bx >> cx (conservando el signo)
	mov ax, bx
	jmp push_resultado_rshift
rshift_mayor_a_16:
	cmp bx, 0 
	jge operando_izq_pos_rshift
	mov ax, -1
	jmp push_resultado_rshift
operando_izq_pos_rshift:
	mov ax, 0
push_resultado_rshift:
	call pushStack	; pushea el resultado de la suma
	mov ax, CODIGO_EXITO
	out dx, ax
fin_rshift:
	jmp main

CLEAR:
	push ax
	push dx
	mov ax, CODIGO_EXITO
	mov dx, [puertoLog]
	out dx, ax							; out 16 en Bitacora: comando procesado con exito
	mov word ptr [tope], 0				; tope = 0 (borrado logico)
	pop dx
	pop ax
	jmp main

HALT:
	mov ax, CODIGO_EXITO
	mov dx, [puertoLog]
	out dx, ax							; out 16 en Bitacora: comando procesado con exito
halt_loop:
	jmp halt_loop


main:
	mov dx, [puertoLog]
	mov ax, CODIGO_NUEVO_COMANDO
	out dx, ax					; out 0: inicio proceso nuevo comando
	in ax, ENTRADA				; ax = comando = in(ENTRADA)
								; esta mal? in recibe un inmediato de 8bits (segun manual) y entrada podria ser de 16 NO LO VAN A CHEQUEAR
								; la cartilla dice 1 o 2 bytes asique valdria
	out dx, ax					; out comando: comando leido
	
	cmp ax,1
	je NUM
	cmp ax,2
	je PORT
	cmp ax,3
	je LOG
	cmp ax,4
	je TOP
	cmp ax,5
	je DUMP
	cmp ax,6
	je _DUP
	cmp ax,7
	je SWAP
	cmp ax,8
	je _NEG
	cmp ax,9
	je FACT
	cmp ax,10
	je SUM
	cmp ax,11
	je _ADD
	cmp ax,12
	je SUBSTRACT
	cmp ax,13
	je MULTIPLY
	cmp ax,14
	je DIVIDE
	cmp ax,15
	je MOD
	cmp ax,16
	je _AND
	cmp ax,17
	je _OR
	cmp ax,18
	je LSHIFT
	cmp ax,19
	je RSHIFT
	cmp ax,254
	je CLEAR
	cmp ax,255
	je HALT

	; default case
	push ax
	mov ax, CODIGO_COMANDO_INVALIDO
	mov dx, [puertoLog]
	out dx, ax	; out 2: codigo de error. comando invalido 
	pop ax

jmp main	;while true

.ports
ENTRADA: 1, 1, 1, 4097, 18, 4, 255


;1, -8, 1, 4097, 19, 4, 255
; shifteo con 20
;1, -8, 1, 20, 19, 4, 255
; rango complemento a 2 : 2^(n-1) -1 = 32767 = 0x7fff = 0111 1111 1111 1111
; 4095 << 15 = -32768 ?
;1, 0x0fff, 1, 15, 18, 4, 255
; 5 mod 3 = 2 EXITO
;1, 5, 1, 3, 15, 4, 255
; 5 mod -3 = -2 ??? wolfram dice 1
;1, 5, 1, -3, 15, 4, 255
; -5 mod 3 = -2 ??? wolfram dice 1
;1, -5, 1, 3, 15, 4, 255
; -5 mod -3 = -2 EXITO
;1, -5, 1, -3, 15, 4, 255
; ERROR EN MOD VER CASO DE TEST 51, 

; REFERENCIAS
; MOD TEST 51, -25 mod 7 me da 4 y deberia ser -4
