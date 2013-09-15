global decode_asm

section .data


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
	movq XMM0, [RDI] ;Cargo 8 bytes en XMM0
	pslldq XMM0, 8 ;Shifteo 8 bytes hacia la izquierda
	lea RDI, [RDI + 8] ;Muevo RDI en 8 bytes
	movq XMM0, [RDI] ;Cargo los otros 8 bytes en XMM0
	
	;Extraer de cada uno el code
	pxor XMM1, XMM1 ;Vacio XMM1
	pxor XMM2, XMM2 ;Vacio XMM2
	pxor XMM5, XMM5 ;Vacio XMM5
	movdqu XMM1, XMM0 ;Copio XMM0 en XMM1
	movdqu XMM2, XMM0 ;Copio XMM0 en XMM2
	pxor XMM7, XMM7 ;Vacio XMM7
	mov RBX, 0x0303030303030303
	movq XMM7, RBX ;Cargo parte baja mascara
	pslldq XMM7, 8 ;Shifteo 8 bytes hacia la izquierda
	movq XMM7, RBX ;Cargo parte baja mascara
	pand XMM1, XMM7 ;Quedo XMM1 = code
	movdqu XMM5, XMM1 ;Copio XMM1 en XMM5
	

	;Extraer de cada uno el op
	mov RBX, 0x0C0C0C0C0C0C0C0C
	movq XMM7, RBX ;Cargo mascara de op
	pslldq XMM7, 8
	movq XMM7, RBX ;Cargo mascara de op
	pand XMM2, XMM7 ;Quedo XMM2 = ops << 2
	
	
	;De acuerdo con el op, modificar el code.
	pxor XMM4, XMM4 
	pxor XMM3, XMM3
	;Si op = 01
	mov RBX, 0x0404040404040404
	movq XMM3, RBX
	pslldq XMM3, 8
	movq XMM3, RBX ;XMM3 = mascara (op = 01)
	pcmpeqb XMM3, XMM2 ;if(op == 01)
	mov RBX, 0x0101010101010101
	movq XMM4, RBX
	pslldq XMM4, 8
	movq XMM4, RBX ;XMM4 = mascara para sumar.
	pand XMM4, XMM3 ;Cuales de los op dieron = 01
	paddb XMM1, XMM4 ;A esos, le sumo 01
	;pand XMM1, XMM7 ;Me quedo con los ultimos 2 bits 
	
	;Si op = 10
	
	mov RBX, 0x0808080808080808
	movq XMM3, RBX
	pslldq XMM3, 8
	movq XMM3, RBX ;XMM3 = mascara (op = 10)
	pcmpeqb XMM3, XMM2 ;if(op == 10)
	mov RBX, 0x0101010101010101
	movq XMM4, RBX
	pslldq XMM4, 8
	movq XMM4, RBX
	pand XMM4, XMM3 ;Cuales de los op dieron = 10
	psubb XMM1, XMM4 ;A esos, le sumo 01
	
	;Si op = 11
	
	mov RBX, 0x0C0C0C0C0C0C0C0C
	movq XMM3, RBX
	pslldq XMM3, 8
	movq XMM3, RBX ;XMM3 = mascara (op = 11)
	pcmpeqb XMM3, XMM2 ;if(op == 11)
	pand XMM4, XMM3 ;Cuales de los op dieron = 11
	pandn XMM1, XMM4 ;A esos, los niego
	
	pand XMM1, XMM7 ;Me quedo con los ultimos 2 bits.
	
	;Al final de todo esto, queda en XMM1 los codes resultantes.
	
	;Extrar los 4 bytes de caracteres.
	pxor XMM5, XMM5 ;Vacio XMM5
	movdqu XMM5, XMM1
	mov RCX, 4
.ciclo:
	pslld XMM5, 10 ;Me muevo 10 bits hacia la izquierda
	psubb XMM1, XMM5 ;Sumo XMM1 con XMM5
	loop .ciclo
	
	pxor XMM6, XMM6
	xor RBX, RBX
	mov R12, 0x0004080C05050505
	movq XMM6, R12
	pslldq XMM6, 8
	mov R12, 0x0505050505050505
	movq XMM6, R12
	pshufb XMM1, XMM6
	movd EBX, XMM1
	
	mov dword [RSI], EBX
	lea RSI, [RSI + 4]
	lea RDI, [RDI + 8]
	cmp dword EBX, 0
	jne .hay_mas
	;insertarlos en RSI y avanzar RDI += 16, RSI += 4
	;Repetir si ninguno de los caracteres es 0. O parar si todos son 0.
	;Fin feliz.
	pop R12
	pop RBX
	pop RBP
    ret
