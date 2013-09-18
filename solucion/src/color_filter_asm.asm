global color_filter_asm

%define width [RBP + 16]
%define height [RBP + 24]
%define CANT_ELEMENTOS R14

section .data

align 16
todos_ceros:	dq 0
				dq 0

section .bss

align 16
color_deseado:	resb 64
				resb 64


section .text
;void color_filter_asm(unsigned char *src,
;                    unsigned char *dst,
;                    unsigned char rc,
;                    unsigned char gc,
;                    unsigned char bc,
;                    int threshold,
;                    int width,
;                    int height);

color_filter_asm:
	;RDI = *src
	;RSI = *dst
	;RDX = rc
	;RCX = gc
	;R8 = bc
	;R9 = int threshold
	;[RBP+16] = width (despues de armar el stack frame)
	;[RBP+24] = height (despues de armar el stack frame)
	
	push RBP
	mov RBP, RSP
	push RBX
	push R12
	push R13
	push R14
	;sub RSP, 8
	
.cargar_color_deseado:
	;Cargo color_deseado en memoria
	xor R13, R13
	mov R13, RCX ;Copio R13 = gc
	xor RCX, RCX ;Vacio RCX
	mov RCX, 2 ;Cargo un 5
	mov R12, color_deseado ;R12 = mm128 reservado
.c_d_ciclo:
	mov RBX, RDX ;RBX = rc
	mov byte [R12], BL ;R12[pixel + c_red]
	inc R12 ;R12++
	mov byte [R12], 0
	inc R12 ;R12++
	mov RBX, R13 ;RBX = gc
	mov byte [R12], BL ;R12[pixel + c_green]
	inc R12 ;R12++
	mov byte [R12], 0
	inc R12 ;R12++
	mov RBX, R8 ;RBX = bc
	mov byte [R12], BL ;R12[pixel + c_blue]
	inc R12 ;R12++
	mov byte [R12], 0
	inc R12
	loop .c_d_ciclo
	mov byte [R12], 0 ;Un byte vacio de borde
	
	
.calcular_tam_imagen:
	;Ya puedo utilizar sin culpa RDX, RCX, R8 y R13
	xor RBX, RBX ;Vacio RBX
	xor RAX, RAX ;Vacio RAX
	xor RDX, RDX ;Vacio RDX
	xor R14, R14
	mov dword EAX, width ;Cargo width en EAX
	mov EDX, 0 ;Cargo 0 en EDX
	mov EBX, height ;Cargo height en EBX
	mul EBX ;EDX:EAX = width*height
	mov EBX, 3 ;Cargo 3 en EBX
	mul EBX ;EDX:EAX = width*height*3
	mov R14, RDX ;Cargo parte alta en R14
	shl R14, 32 ;Shifteo R14
	mov R14, RAX ;Cargo parte baja en R14
	;R14 = width*height*3 = CANT_ELEMENTOS.

.inicio:
	cmp R14, 0
	je .fin
.levantar_pixeles:
	pxor XMM0, XMM0 ;Vacio XMM0
	;Muevo a XMM0 5 pixeles + 1 byte de basura
	movdqu XMM0, [RDI]
	pxor XMM1, XMM1 ;Vacio XMM1
	movdqu XMM1, XMM0 ;Copio XMM0 en XMM1
.antes:
	punpcklbw XMM1, [todos_ceros] ;Aumento la precision de byte a word
	psubusb XMM1, [color_deseado] ;Resto (rc,gc,bc) a todos los valores de XMM0 
	;Tengo en XMM1 = (word)(canal - canal_c)
	pmullw XMM1, XMM1 ;Elevo al cuadrado cada valor.
	punpcklwd XMM1, [todos_ceros] ;Aumento la precision de word a dword
	pxor XMM2, XMM2 ;Vacio XMM2
	movdqu XMM2, XMM1 ;Copio XMM1 en XMM2
	xor RCX, RCX
	mov RCX, 2
.suma_ciclo:
	psrldq XMM2, 4
	paddd XMM1, XMM2
	loop .suma_ciclo
.tengo_casi_todo:
	cvtdq2pd XMM1, XMM1
	sqrtpd XMM1, XMM1
	cvtsd2si RBX, XMM1
	xor RAX, RAX
	mov RAX, R9
	cmp EBX, EAX
	jg .es_mayor
	movd EBX, XMM0
	mov [RSI], BL ;DL = r
	inc RSI
	shr EBX, 8
	mov [RSI], BL
	inc RSI
	shr EBX, 8
	mov [RSI], BL
	inc RSI
	sub R14, 3
	add RDI, 3
	jmp .inicio	
.es_mayor:
	xor RBX, RBX
	xor RAX, RAX
	xor RDX, RDX
	movd EBX, XMM0
	mov DL, BL ;DL = r
	add RAX, RDX ;RAX = r
	shr EBX, 8
	mov DL, BL ;DL = g
	add RAX, RDX ;RAX = r + g
	shr EBX, 8
	mov DL, BL ;DL = b
	add RAX, RDX ;RAX = r + g + b
	xor RDX, RDX
	xor RBX, RBX
	mov RBX, 3
	div RBX
	mov [RSI], AL
	inc RSI
	mov [RSI], AL
	inc RSI
	mov [RSI], AL
	inc RSI
	sub R14, 3
	add RDI, 3
	jmp .inicio
.fin:
	;add RSP, 8
	pop R14
	pop R13
	pop R12
	pop RBX
	pop RBP
    ret