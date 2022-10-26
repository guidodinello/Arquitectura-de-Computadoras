.data
#define DS 100h

CODIGO_EXITO EQU 16
CODIGO_FALTA_OPERANDOS EQU 8
CODIGO_DESBORDAMIENTO EQU 4
CODIGO_COMANDO_INVALIDO EQU 2
CODIGO_NUEVO_COMANDO EQU 0

ENTRADA EQU 1
PUERTO_SALIDA_DEFECTO EQU 2
PUERTO_LOG_DEFECTO EQU 0x03
STACK_SIZE EQU 31

stack DW DUP(STACK_SIZE) ?
tope dw 0	; deberia ser db como el tamano es 31 podria usar un byte

DOBLE_STACK_SIZE EQU STACK_SIZE*2	; servira para chequear si la pila esta llena

puertoLog dw PUERTO_LOG_DEFECTO
puertoSalida dw PUERTO_SALIDA_DEFECTO

.code
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx
	jmp main

; recibe el parametro en el registro AX
pushStack proc
	push di						; preservamos el valor de di
	mov di, [tope]				; indice del ultimo elmento del stack
	mov word ptr [stack+di],ax 	; stack[tope] = ax
	inc word ptr [tope] 		; 
	inc word ptr [tope]			; tope ++
	pop di
	ret
pushStack endp

; retorna el resultado en el registro BX
popStack proc
	push di
	dec word ptr [tope]			; 
	dec word ptr [tope]			; tope --;
	mov di, [tope]
	mov bx, [stack+di]			; ax = stack[tope]
	pop di
	ret
popStack endp

; recibe el parametro en el registro AX
; retorna el resultado en DX::AX
factorial proc
	cmp ax, 0			; n==0 ?
	je paso_base		; return 1
	push bx				; 
	push ax				; 
	dec ax				; n' = n-1
	call FACT			; ax = factorial(n')
	inc ax
	pop bx
	mov cx, ax
	mul bx				; dx::ax = ax * bx
	mov bx, ax
	mov ax, cx
	jmp fin_factorial				; return n * factorial(n')

paso_base:
	mov bx, 1			
fin_factorial:
	ret
factorial endp

NUM:
	push ax
	push bx									; preservo valores de registros
	push dx
	in ax, ENTRADA							; leo parametro
	mov dx, [puertoLog]						;
	out dx, ax								; out en bitacora del parametro leido
	cmp word ptr [tope], DOBLE_STACK_SIZE	; if (tope == stack_size)
	jne exito_num							
	mov ax, CODIGO_DESBORDAMIENTO
	out dx, ax							; out 4 : desbordamiento de la pila
	jmp fin_num
exito_num:
	call pushStack						; se agrega el parametro al stack
	mov ax, CODIGO_EXITO
	out dx, ax							; out 16 : proceso exitoso
fin_num:
	pop dx
	pop bx
	pop ax
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
	push dx									; preservo valores de registros
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
	mov di, [tope]					; di = tope
	sub di, 2						; di = tope - 1
	mov ax, [stack+di]				; ax = stack[tope]
	mov dx, [puertoSalida]			; dx = puertoSalida
	out dx, ax						; out en salida del tope de la pila
	mov ax, CODIGO_EXITO			; ax = 16
	mov dx, [puertoLog] 			; dx = puertoLog
	out dx, ax						; out 16 : proceso exitoso		
	pop di			
fin_top:
	push dx
	push ax
	jmp main

DUMP:
	push ax
	push dx
	push di
	mov di, [tope]
	mov dx, [puertoSalida]			; dx = puertoSalida, hacer esta asignacion aca evita estar repitiendola
									; innecesariamente en cada iteracion del while
while_dump:
	cmp di, 0
	je fin_dump						; index > 0 ?
	sub di, 2						; 
	mov ax, [stack+di]				; ax = stack[tope - 1]
	out dx, ax						; out en salida del tope de la pila
	jmp while_dump
fin_dump:							; index <= 0
	mov ax, CODIGO_EXITO			; ax = 16
	mov dx, [puertoLog] 			; dx = puertoLog
	out dx, ax						; out 16 : proceso exitoso		
	pop di
	pop dx
	pop ax
	jmp main

_DUP:
	push ax									
	push dx
	mov dx, [puertoLog]						; dx = puertoLog
	cmp word ptr [tope], DOBLE_STACK_SIZE	; if (tope == stack_size)
	je pila_llena_dup
	cmp word ptr [tope], 0					; if (tope == 0)
	je pila_vacia_dup	
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

FACT:	; FUNCIONA MAL
	push ax
	push dx
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
	call factorial			; dx::ax = fact(ax)
	call pushStack			; stack[tope] = ax
	mov ax, CODIGO_EXITO	; ax = 16
	out dx, ax				; out 16 : operacion exitosa
fin_fact:
	pop ax
	pop dx
	jmp main

SUM:
	push ax
	push bx
	push dx
	xor ax, ax					; acum = 0
while_sum:
	cmp word ptr [tope], 0
	je fin_sum						; tope > 0 ?
	call popStack					; bx = pop()
	add ax, bx						; ax += bx
	jmp while_sum
fin_sum:							; index <= 0
	call pushStack
	mov ax, CODIGO_EXITO			; ax = 16
	mov dx, [puertoLog] 			; dx = puertoLog
	out dx, ax						; out 16 : proceso exitoso		
	pop dx
	pop bx
	pop ax
	jmp main

_ADD:
	jmp main

SUBSTRACT:
	jmp main

MULTIPLY:
	jmp main

DIVIDE:
	jmp main

MOD:
	jmp main

_AND:
	jmp main

_OR:
	jmp main

LSHIFT:
	jmp main

RSHIFT:
	jmp main

CLEAR:
	push ax
	push dx
	mov ax, CODIGO_EXITO
	mov dx, [puertoLog]
	out dx, ax							; out 16 en Bitacora: comando procesado con exito
	mov word ptr [tope], 0				; tope = 0
	pop dx
	pop ax
	jmp main

HALT:
	mov ax, CODIGO_EXITO
	mov dx, [puertoLog]
	out dx, ax							; out 16 en Bitacora: comando procesado con exito
	hlt	
halt_loop:
	jmp halt_loop


main:
	mov dx, [puertoLog]
	mov ax, CODIGO_NUEVO_COMANDO
	out dx, ax					; out 0: inicio proceso nuevo comando
	in ax, ENTRADA				; ax = comando = in(ENTRADA)
								; esta mal? in recibe un inmediato de 8bits (segun manual) y entrada podria ser de 16
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
ENTRADA: 1, 1, 1, 2, 1, 3, 1, 4, 1, 5, 10, 4, 255
;1, 1, 1, 2, 5, 7, 5, 5, 8, 4, 7, 8, 4, 255
