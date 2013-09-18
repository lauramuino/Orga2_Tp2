global color_filter_asm

section .data

align 16
todos_ceros:	dq 0
				dq 0

section .bss

align 16
threshold:	resb 64
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
	;[RSP+0] = width
	;[RSP + 8] = height
	push RBP
	mov RBP, RSP
	push RBX
	push R12
	push R13
	push R14
	;sub RSP, 8
	xor R14, R14
	mov dword EAX, [RSP]
	mul dword [RSP + 8]
	mov R14, 3
	mul R14
	mov R14, RAX
	;Cargo threshold en memoria
	xor R13, R13
	mov R13, RCX ;Copio RCX en R13
	xor RCX, RCX ;Vacio RCX
	mov RCX, 2 ;Cargo un 5
	mov R12, threshold ;R12 = mm128
.t_ciclo:
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
	loop .t_ciclo
	mov byte [R12], 0 ;Un byte vacio de borde
	pxor XMM0, XMM0 ;Vacio XMM0
	;Muevo a XMM0 5 pixeles + 1 byte de basura
	movdqu XMM0, [RDI]
	pxor XMM1, XMM1 ;Vacio XMM1
	movdqu XMM1, XMM0 ;Copio XMM0 en XMM1
.antes:
	punpcklbw XMM1, [todos_ceros] ;Aumento la precision de byte a word
	psubusb XMM1, [threshold] ;Resto (rc,gc,bc) a todos los valores de XMM0 
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
	;cmp dword RBX, R9
	jg .es_mayor
	
.es_mayor:
	xor RBX, RBX
	movd EBX, XMM0
	xor R12, R12
	;add R12, BL
	shr EBX, 8
	;add R12, BL
	shr EBX, 8
	;add R12, BL
	mov RAX, R12
	xor RDX, RDX
	;div 3
	mov [RSI], RAX
	inc RSI
	mov [RSI], RAX
	inc RSI
	mov [RSI], RAX
	inc RSI
.fin:
	;add RSP, 8
	pop R14
	pop R13
	pop R12
	pop RBX
	pop RBP
    ret