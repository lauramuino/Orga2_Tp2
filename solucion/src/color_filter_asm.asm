global color_filter_asm

%define width [RBP + 16]
%define height [RBP + 24]
%define CANT_ELEMENTOS R14

section .data

align 16
todos_ceros:	dq 0
				dq 0
mask_gris:		dd 0xFFFFFFFF, 0x0
				dd 0x0, 0xFFFFFFFF
un_tercio:		dq 0.3333333333
				dq 0.3333333333
mask_broadcast:	db 0x00,0x00,0x00,0x01,0x01,0x01,0x02,0x02
				db 0x02,0x03,0x03,0x03,0x00,0x00,0x00,0x00
mask_comp:		db 0x00,0x00,0x00,0x04,0x04,0x04,0x08,0x08
				db 0x08,0x0C,0x0C,0x0C,0x0C,0x0D,0x0E,0x0F
solo_4_bytes:	db 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
				db 0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x00

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
	sub RSP, 32
	
.cargar_color_deseado:
	;Cargo color_deseado en memoria
	xor R13, R13
	mov R13, RCX ;Copio R13 = gc
	xor RCX, RCX ;Vacio RCX
	mov RCX, 2 ;Cargo un 5
	mov R12, color_deseado ;R12 = mm128 reservado
.c_d_ciclo:
	;RDX = rc/R13 = gc/R8 = bc
	;mov RBX, R8 ;RBX = bc
	mov byte [R12], R8B ;R12[pixel + c_blue]
	inc R12 ;R12++
	mov byte [R12], 0
	inc R12 ;R12++
	;mov RBX, R13 ;RBX = gc
	mov byte [R12], R13B ;R12[pixel + c_green]
	inc R12 ;R12++
	mov byte [R12], 0
	inc R12 ;R12++
	;mov RBX, RDX ;RBX = rc
	mov byte [R12], DL ;R12[pixel + c_red]
	inc R12 ;R12++
	mov byte [R12], 0
	inc R12
	loop .c_d_ciclo
	;mov byte [R12], 0 ;Un byte vacio de borde
	
	
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
	shl R14, 32 ;Shifteo a izq R14
	mov R14, RAX ;Cargo parte baja en R14
	;R14 = width*height*3 = CANT_ELEMENTOS.
	
.inicio:
	cmp R14, 0
	jle .fin
.levantar_pixeles:
	;Muevo a XMM0 4 pixeles + 4 byte de basura
	pxor XMM0, XMM0 ;Vacio XMM0
	pxor XMM1, XMM1
	pxor XMM2, XMM2
	cmp R14, 12 ;Si es un caso borde
	jne .no_borde
	sub RDI, 4 ;Retrocedo el cursor
	sub RSI, 4
	movdqu XMM0, [RDI]
	psrldq XMM0, 4
	jmp .continuo ;Proceso como siempre
.no_borde:
	movdqu XMM0, [RDI]
.continuo:
	movdqu XMM1, XMM0 ;Copio XMM0 en XMM1
	movdqu XMM2, XMM0 ;Copio XMM0 en XMM2
.a_word:
	;movdqu XMM15, [todos_ceros]
	pxor XMM15, XMM15
	punpcklbw XMM1, XMM15 ;Convierto a word y guardo en XMM1
	pslldq XMM2, 2 ;Shifteo para acomodar datos
	punpckhbw XMM2, XMM15 ;Convierto a word y guardo en XMM2
	movdqu XMM3, XMM1 ;Copio XMM1 en XMM3
	movdqu XMM4, XMM2 ;Copio XMM2 en XMM4

.calcular_gris:
	movdqu XMM14, [mask_gris] ;Cargo mascara
	
	;Calcular gris para pixeles en XMM3
	movdqu XMM5, XMM3 ;copio XMM3 en XMM5
	psrldq XMM5, 2
	paddw XMM3, XMM5
	psrldq XMM5, 2
	paddw XMM3, XMM5 ;Consigo sumar r+g+b
	punpcklwd XMM3, XMM15 ;XMM3 = (dword)r+g+b 2do pixel|x|x|(dword)r+g+b 1er pixel
	pand XMM3, XMM14 ;XMM3 = (dword)r+g+b 2do pixel|0|0|(dword)r+g+b 1er pixel
	movdqu XMM5, XMM3
	psrldq XMM5, 8
	paddd XMM3, XMM5 ;XMM3 = x|0|(dword)r+g+b 2do pixel|(dword)r+g+b 1er pixel
	
	;Calcular gris para pixeles en XMM4
	movdqu XMM5, XMM4
	psrldq XMM5, 2
	paddw XMM4, XMM5
	psrldq XMM5, 2
	paddw XMM4, XMM5
	punpcklwd XMM4, XMM15 ;XMM4 = (dword)r+g+b 4to pixel|x|x|(dword)r+g+b 3er pixel
	pand XMM4, XMM14 ;XMM4 = (dword)r+g+b 4to pixel|0|0|(dword)r+g+b 3er pixel
	movdqu XMM5, XMM4
	psrldq XMM5, 8
	paddd XMM4, XMM5 ;XMM4 = x|0|(dword)r+g+b 4to pixel|(dword)r+g+b 3er pixel
	
	
	;Convertir a double pixeles en XMM3
	cvtdq2pd XMM3, XMM3 ; XMM3 = (double)2do|(double)1er
	
	;Convertir a double pixeles en XMM4
	cvtdq2pd XMM4, XMM4 ; XMM4 = (double)4to|(double)3er
	
	;Divido por 3 los pixeles en XMM3
	mulpd XMM3, [un_tercio]
	
	;Divido por 3 los pixeles en XMM4
	mulpd XMM4, [un_tercio]
	
	;Convierto a dword(con redondeo normal) los pixeles de XMM3
	cvtpd2dq XMM3, XMM3 
	
	;Convierto a dword(con redondeo normal) los pixeles de XMM4
	cvtpd2dq XMM4, XMM4
	
	;Acumulo pixeles en XMM3
	pslldq XMM4, 8
	paddd XMM3, XMM4 ; XMM3 = (r+g+b)/3 4to|(r+g+b)/3 3er |(r+g+b)/3 2do|(r+g+b)/3 1er 
	
	;Convierto de dword a word 
	packssdw XMM3, XMM3 ;XMM3 = (qword)x|(r+g+b)/3 4to|(r+g+b)/3 3er |(r+g+b)/3 2do|(r+g+b)/3 1er 
	
	;Convierto de word a byte
	packuswb XMM3, XMM3 ;XMM3 = (qword)x|(dword)x|(r+g+b)/3 4to|(r+g+b)/3 3er |(r+g+b)/3 2do|(r+g+b)/3 1er
	
	;Copio el mismo resultado a todos los canales
	pshufb XMM3, [mask_broadcast]
	movdqu XMM11, XMM3
	;XMM11 tiene los valores reproducidos para llegar a todos los pixeles
	
	
.calcular_dist:
	movdqu XMM14, [color_deseado]
	
	;Resto (rc,gc,bc) a todos los valores de XMM1
	psubw XMM1, XMM14
	
	;Resto (rc,gc,bc) a todos los valores de XMM2
	psubw XMM2, XMM14
	
	;Tengo en XMM1 = (word)rgb(canal - canal_c) de los 2 primeros pixeles
	;Tengo en XMM2 = (word)rgb(canal - canal_c) de los 2 ultimos pixeles
	
	;Elevo al cuadrado cada valor de XMM1
	pmullw XMM1, XMM1 
	
	;Elevo al cuadrado cada valor de XMM2
	pmullw XMM2, XMM2 
	
	;Copio cosas
	movdqu XMM3, XMM1 ;Copio XMM1 en XMM3
	movdqu XMM4, XMM2 ;Copio XMM2 en XMM4
	
	;Convierto los valores de XMM1 a dword
	punpcklwd XMM1, XMM15 ;XMM1 = (dword) rgb primer pixel
	
	;Convierto los valores de XMM3 a dword
	psrldq XMM3, 6
	punpcklwd XMM3, XMM15 ;XMM3 = (dword) rgb segundo pixel
	
	;Convierto los valores de XMM2 a dword
	punpcklwd XMM2, XMM15 ;XMM2 = (dword) rgb tercer pixel
	
	;Convierto los valores de XMM4 a dword
	psrldq XMM4, 6
	punpcklwd XMM4, XMM15 ;XMM4 = (dword) rgb cuarto pixel
	
	;Sumo r+g+b para XMM1 y convierto a double
	movdqu XMM5, XMM1
	psrldq XMM5, 4
	paddd XMM1, XMM5
	psrldq XMM5, 4
	paddd XMM1, XMM5
	cvtdq2pd XMM1, XMM1 ;(double)r+g+b en primer qword 
	
	;Sumo r+g+b para XMM3 y convierto a double
	movdqu XMM5, XMM3
	psrldq XMM5, 4
	paddd XMM3, XMM5
	psrldq XMM5, 4
	paddd XMM3, XMM5
	cvtdq2pd XMM3, XMM3 ;(double)r+g+b en primer qword
	
	;Sumo r+g+b para XMM2 y convierto a double
	movdqu XMM5, XMM2
	psrldq XMM5, 4
	paddd XMM2, XMM5
	psrldq XMM5, 4
	paddd XMM2, XMM5
	cvtdq2pd XMM2, XMM2 ;(double)r+g+b en primer qword
	
	;Sumo r+g+b para XMM4 y convierto a double
	movdqu XMM5, XMM4
	psrldq XMM5, 4
	paddd XMM4, XMM5
	psrldq XMM5, 4
	paddd XMM4, XMM5
	cvtdq2pd XMM4, XMM4 ;(double)r+g+b en primer qword
	
	;Mezclo XMM1 y XMM3 en XMM1
	shufpd XMM1, XMM3, 0 ;XMM1 = (qword)r+g+b 2do pixel | (qword)r+g+b 1er pixel 
	
	;Mezclo XMM2 y XMM4 en XMM2
	shufpd XMM2, XMM4, 0 ;XMM2 = (qword)r+g+b 4to pixel | (qword)r+g+b 3er pixel 
	
	;Hago raiz cuadrada de XMM1
	sqrtpd XMM1, XMM1 
	
	;Hago raiz cuadrada de XMM2
	sqrtpd XMM2, XMM2
	
	;Preparo para redondear hacia arriba
	xor RAX, RAX ;Limpio RAX
	stmxcsr dword [RSP + 8] ;[RSP+8]=MXCSR
	stmxcsr dword [RSP + 16] ;[RSP+16]=MXCSR
	mov EAX, [RSP+8] ;EAX=MXCSR
	or EAX, 0x00004000 ;EAX=MXCSR con redondeo hacia arriba
	mov [RSP+8], EAX ;[RSP+8] = MXCSR modificado
	ldmxcsr dword [RSP+8] ;Modifico efectivamente MXCSR
	
	;Convierto, con ceil(), XMM1 a dword
	cvtpd2dq XMM1, XMM1 ; XMM1 = (qword) 0 | (dword)2do pixel | (dword) 1er pixel
	
	;Convierto, con ceil(), XMM2 a dword
	cvtpd2dq XMM2, XMM2 ; XMM2 = (qword) 0 | (dword)4to pixel | (dword) 3er pixel
	
	;Reestablezco redondeo normal
	ldmxcsr dword [RSP+16] ;Reestablezco MXCSR
	
	;Combino datos en XMM1
	pslldq XMM2, 8
	paddd XMM1, XMM2 ;XMM1 = (dword)4to pixel | (dword)3er pixel | (dword)2do pixel | (dword)1er pixel
	
.comparar_dist:
	
	;Cargo threshold en XMM13
	pxor XMM2, XMM2 ;Limpio XMM2
	movdqu XMM2, XMM1 ;Copio XMM1 en XMM2
	xor RBX, RBX ;Limpio RBX
	xor RAX, RAX
	mov EBX, R9D
	mov EAX, R9D
	shl RAX, 32
	add RBX, RAX
	movq XMM13, RBX ;XMM13 = 0 | 0 | threshold | threshold
	movdqu XMM12, XMM13
	pslldq XMM12, 8
	paddd XMM13, XMM12 ;XMM13 = threshold | threshold | threshold | threshold
	
	;Realizo comparacion
	pcmpgtd XMM2, XMM13 ;XMM2 = Si dist > threshold
	
	;"Desempaqueto" el resultado de la comparacion
	pshufb XMM2, [mask_comp]
	pand XMM2, [solo_4_bytes]
	;Hay FF sobre los bytes a cambiar y 00 sobre los otros(y 0 sobre los que nisiquiera modifico)
	pand XMM11, XMM2 ;Me quedo de XMM1(grises) los valores que dieron mayor al threshold
	pandn XMM2, XMM0 
	;XMM2 tiene los valores modificados de los pixeles a cambiar. Hay que sumarle los que no hay que cambiar
	paddb XMM2, XMM11
	
	;Guardo resultado en dst*
	movdqu [RSI], XMM2
	
	;Avanzo las posiciones de memoria
	add RSI, 12
	add RDI, 12
	sub R14, 12
	jmp .inicio 

.fin:
	add RSP, 32
	pop R14
	pop R13
	pop R12
	pop RBX
	pop RBP
    ret
