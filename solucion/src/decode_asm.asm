global decode_asm

section .data

mask_2bits:		db 0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03
				db 0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03
mask_4bits:		db 0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C
				db 0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C
mask_op_1:		db 0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04
				db 0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04
mask_op_2:		db 0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
				db 0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
mask_op_3:		db 0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C
				db 0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C
mask_suma_1:	db 0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01
				db 0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01
mask_shifteo:	db 0x00,0x04,0x08,0x0C,0x0D,0x0D,0x0D,0x0D
				db 0x0D,0x0D,0x0D,0x0D,0x0D,0x0D,0x0D,0x0D

section .text
;void decode_asm(unsigned char *src,
;              unsigned char *code,
;              int width,
;              int height);

decode_asm:
	push RBP
	mov RBP, RSP
	push RBX
	push R12
	;Mover a xmm0 16 bytes de imagen
.hay_mas:
	pxor XMM0, XMM0 ;Vacio XMM0
	movdqu XMM0, [RDI] ;Cargo 16 bytes en XMM0
	
	;Extraer de cada uno el code
	pxor XMM1, XMM1 ;Vacio XMM1
	pxor XMM2, XMM2 ;Vacio XMM2
	
	movdqu XMM1, XMM0 ;Copio XMM0 en XMM1
	movdqu XMM2, XMM0 ;Copio XMM0 en XMM2
	
	pxor XMM7, XMM7 ;Vacio XMM7
	movdqu XMM7, [mask_2bits]
	pand XMM1, XMM7 ;Quedo XMM1 = code
	

	;Extraer de cada uno el op
	movdqu XMM7, [mask_4bits]
	pand XMM2, XMM7 ;Quedo XMM2 = ops << 2
	
	pxor XMM0, XMM0 ;Vacio XMM0 para usarlo de acumulador
	
	
	;De acuerdo con el op, modificar el code.
	pxor XMM4, XMM4
	pxor XMM3, XMM3
	;Si op = 01
	movdqu XMM3, [mask_op_1]
	pcmpeqb XMM3, XMM2 ;if(op == 01)
	movdqu XMM4, [mask_suma_1]
	pand XMM4, XMM3 ;Cuales de los op dieron = 01
	paddb XMM1, XMM4 ;A esos, le sumo 01
	pand XMM3, XMM1
	paddb XMM0, XMM3
	
	;Si op = 10
	movdqu XMM3, [mask_op_2]
	pcmpeqb XMM3, XMM2 ;if(op == 10)
	movdqu XMM4, [mask_suma_1]
	pand XMM4, XMM3 ;Cuales de los op dieron = 10
	psubb XMM1, XMM4 ;A esos, le resto 01
	pand XMM3, XMM1
	paddb XMM0, XMM3
	
	;Si op = 11
	
	movdqu XMM3, [mask_op_3]
	pcmpeqb XMM3, XMM2 ;if(op == 11)
	;pand XMM4, XMM3 ;Cuales de los op dieron = 11
	pandn XMM1, XMM3 ;A esos, los niego
	
	movdqu XMM7, [mask_2bits]
	pand XMM1, XMM7 ;Me quedo con los ultimos 2 bits.
	paddb XMM0, XMM1
	
	;Al final de todo esto, queda en XMM0 los codes resultantes.
	
	;Extrar los 4 bytes de caracteres.
	pxor XMM5, XMM5 ;Vacio XMM5
	movdqu XMM5, XMM0
	mov RCX, 3
.ciclo:
	psrld XMM5, 6 ;Me muevo 6 bits hacia la derecha
	paddb XMM0, XMM5 ;Sumo XMM0 con XMM5
	loop .ciclo
	
	pxor XMM6, XMM6
	xor RBX, RBX
.antes:	movdqu XMM6, [mask_shifteo]
	pshufb XMM0, XMM6
	movd EBX, XMM0
	
	mov dword [RSI], EBX
	lea RSI, [RSI + 4]
	lea RDI, [RDI + 16]
	cmp dword EBX, 0
	jne .hay_mas
	;insertarlos en RSI y avanzar RDI += 16, RSI += 4
	;Repetir si ninguno de los caracteres es 0. O parar si todos son 0.
	;Fin feliz.
	pop R12
	pop RBX
	pop RBP
    ret
