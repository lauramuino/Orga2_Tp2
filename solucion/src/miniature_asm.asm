global miniature_asm

section .data
md2:    dw 0x0001,0x0005,0x0012,0x0005,0x0001,0x0000,0x0000,0x0000
md1:	dw 0x0005,0x0020,0x0040,0x0020,0x0005,0x0000,0x0000,0x0000
md0:	dw 0x0012,0x0040,0x0064,0x0040,0x0012,0x0000,0x0000,0x0000
					
mask_btow_b:		db 0x00,0xff,0x03,0xff,0x06,0xff,0x09
					db 0xff,0x0c,0xff,0xff,0xff,0xff,0xff
					db 0xff,0xff

mask_btow_g:		db 0x01,0xff,0x04,0xff,0x07,0xff,0x0a
					db 0xff,0x0d,0xff,0xff,0xff,0xff,0xff
					db 0xff,0xff

mask_btow_r:		db 0x02,0xff,0x05,0xff,0x08,0xff,0x0b
					db 0xff,0x0e,0xff,0xff,0xff,0xff,0xff
					db 0xff,0xff
					
restar_top: 		dd 0x00
restar_bot:			dd 0x00

seiscientos:		dd 600

section .text

; void miniature_asm(unsigned char *src,
;                unsigned char *dst,
;                int width,
;                int height,
;                float topPlane,
;                float bottomPlane,
;                int iters);


miniature_asm:
	push RBP
	mov RBP, RSP
	push R11
	push R12
	push R13
	push R14
	push R15
	push RBX

	;RDI: src
	;RSI: dst
	;EDX: width
	;ECX: height
	;XMM0: topPlane ;en 32 bits!
	;XMM1: bottomPlane ;en 32 bits!
	;R8D: iters
		
								;R8D = iters
	mov R14, RDI				;R14 = src*
	mov R15, RSI				;R15 = dst*
	mov R9D, 1 					;R9D = iteracion_actual
	xor R12d, R12d				;R12d = filas_top
	xor R13d, R13d				;R13d = filas_bot		
	xor RDI, RDI
	xor RSI, RSI
.hola:
;Copiar primero..
	xor rdi, rdi
	pxor xmm2, xmm2
	pxor xmm3, xmm3
	movd xmm2, edx
	movd xmm3, ecx
	CVTDQ2PS xmm3, xmm3
	CVTDQ2PS xmm2, xmm2
	mulps xmm3, xmm2		;xmm3 = 0|0|0|height*width(float)
	cvtss2si edi, xmm3
	mov esi, edi
	add edi, edi
	add edi, esi			;edi = height*width*3
	sub edi, 16
	mov esi, 0
	
.copiar_primero:
	movdqu xmm2, [r14 + rsi]
	movdqu [r15 + rsi], xmm2
	add esi, 16
	cmp esi, edi
	jg .salir_copiar_primero
	jmp .copiar_primero
.salir_copiar_primero




;filas_top = height*topPlane 
;filas_bot = height - bottomPlane*height
;---------------------------------------

	xor r11, r11
	shl rcx, 32
	shr rcx, 32
	mov r11, rcx
	shl r11, 32
	add r11, rcx				;r11 = height | height
	movq xmm2, r11				;xmm2 = basura | basura | height | height (ints)
	CVTDQ2PS xmm2, xmm2			;xmm2 = basura | basura | height | height (floats)
	;xor r11, r11
	pslldq xmm0, 4
	addps xmm0, xmm1
	movdqu xmm3, xmm0
	;movd r11d, xmm0
	;shl r11, 32
	;movd r11d, xmm1
	;movq xmm3, r11				;xmm3 = basura | basura | topPlane | bottomPlane (floats)
	mulps xmm2, xmm3			;xmm2 = basura | basura | topPlane*height | bottomPlane*height (floats)
	CVTPS2DQ xmm2, xmm2			;xmm2 = basura | basura | topPlane*height | bottomPlane*height (ints)
	movq r11, xmm2				;r11 = topPlane*height | bottomPlane*height (ints)
	mov R13d, ecx
	sub R13d, R11d				;r13d = filas_bot (int)
	shr r11, 32
	mov R12d, r11d				;r12d = filas_top (int)
;---------------------------------------

xor rdi, rdi
xor rsi, rsi

pxor xmm0, xmm0
pxor xmm1, xmm1
pxor xmm2, xmm2
cvtsi2sd xmm0, r13d
cvtsi2sd xmm1, r12d
cvtsi2sd xmm2, r8d
divsd xmm0, xmm2
divsd xmm1, xmm2
cvtsd2si edi, xmm0
cvtsd2si esi, xmm1
mov [restar_bot], edi
mov [restar_top], esi

.iteraciones:
;indice_actual_top = width*2 +2;
;indice_fin_top = filas_top*width-1;
;---------------------------------------
	xor r10, r10
	xor r11, r11
	mov r11d, edx
	add r11d, edx
	add r11d, 2					;r11d = pixel_actual_top
	mov r10d, r11d
	add r11d, r11d
	add r11d, r10d				;r11d = indice_actual_top

	movd xmm0, edx
	movd xmm1, r12d
	CVTDQ2PS xmm0, xmm0
	CVTDQ2PS xmm1, xmm1			;convertir a floats 32b

	mulss xmm0, xmm1			;xmm0 = basura | basura | basura | filas_top*width
	cvtss2si r10d, xmm0			;r10d = filas_top*width dword
	;movd r10d, xmm0			
	sub r10d, 3				;r10d = filas_top*width - 1
	mov edi, r10d
	add r10d, r10d
	add r10d, edi				;r10d = indice_fin_top
;---------------------------------------
	push r12
	push r13


;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< IT TOP >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.iteraciones_top:
;agregado para probar:
	cmp r11d, 353817
	je .aca
	jmp .no_aca
.aca:
	cmp r11, r11
.no_aca:
;hasta aca agregado..

	mov edi, edx
	add edi, edx
	add edi, edx		;edi = width*3

	xor r13, r13
	mov r13d, r11d
	sub r13d, 6

	movdqu xmm2, [r14+r13]
	add r13d, edi

	movdqu xmm3, [r14+r13]
	add r13d, edi

	movdqu xmm4, [r14+r13]
	xor r13, r13
	mov r13d, r11d
	sub r13d, 6
	sub r13d, edi

	movdqu xmm1, [r14+r13]
	sub r13d, edi

	movdqu xmm0, [r14+r13]

;
;	xmm0 = ma2_1 | ma2_2 | ma2_3 | ma2_4 | ma2_5 | basura(1byte)
;	xmm1 = ma1_1 | ma1_2 | ma1_3 | ma1_4 | ma1_5 | basura(1byte)
;	xmm2 = ma0_1 | ma0_2 | ma0_3 | ma0_4 | ma0_5 | basura(1byte)
;	xmm3 = me1_1 | me1_2 | me1_3 | me1_4 | me1_5 | basura(1byte)
;	xmm4 = me2_1 | me2_2 | me2_3 | me2_4 | me2_5 | basura(1byte)
;

	pxor xmm10, xmm10
	pxor xmm11, xmm11

;--------------------AZULES---------------------
;---------------------xmm0----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm0
	pshufb xmm5, [mask_btow_b]		;xmm5 = 0 0 0 0 0 0 0 b4 0 b3 0 b2 0 b1 0 b0

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6			;xmm5 = multiplicacion de la parte baja (int dwords)
	punpcklwd xmm5, xmm6			;xmm7 = multiplicacion de la parte alta (int dwords)

	cvtdq2ps xmm5, xmm5 			;(convierte dwords int a floats)
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5				;xmm10 = sumas parciales azules (float 32bits)
	addps xmm10, xmm7

	;Repito lo mismo para las otras 4 lineas de pixeles, para azul:
;---------------------xmm1----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm1
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;---------------------xmm2----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm2
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md0] 
	pmulhw xmm6, [md0]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;---------------------xmm3----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm3
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;---------------------xmm4----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm4
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
	
;------------------fin azules-------------------
	xor rax, rax
	;esi  suma de todas las parciales
	;en xmm10 esta las 4 sumas parciales

	pxor xmm12, xmm12					;xmm10 = 1 | 2 | 3 | 4
	haddps xmm10, xmm12					;xmm10 = 0 | 0| 1+2 | 3+4 
	haddps xmm10, xmm12					;xmm10 = 0 | 0 | 0 | 1+2+3+4

	movd xmm11, [seiscientos]
	cvtdq2ps xmm11, xmm11
	divss xmm10, xmm11
	cvttss2si eax, xmm10	;convierte single-float_point a dword int y guarda en esi
	mov [r15 +r11], al




	add r11d, 1
	pxor xmm10, xmm10
	pxor xmm11, xmm11

;ahora para los verdes es lo mismo, lo unico que usando la mascara para verdes..
;--------------------VERDES---------------------
;---------------------xmm0----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm0
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm1----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm1
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm2----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm2
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md0] 
	pmulhw xmm6, [md0]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm3----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm3
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm4----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm4
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;------------------fin verdes-------------------
	xor rax, rax

	pxor xmm12, xmm12					;xmm10 = 1 | 2 | 3 | 4
	haddps xmm10, xmm12					;xmm10 = 0 | 0| 1+2 | 3+4
	haddps xmm10, xmm12					;xmm10 = 0 | 0 | 0 | 1+2+3+4
	
	movd xmm11, [seiscientos]
	cvtdq2ps xmm11, xmm11
	divss xmm10, xmm11
	cvttss2si eax, xmm10	;convierte single-float_point a dword int y guarda en esi
	mov [r15+r11], al

	add r11d, 1
	pxor xmm10, xmm10
	pxor xmm11, xmm11

;--------------------ROJOS----------------------
;---------------------xmm0----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm0
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm1----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm1
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm2----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm2
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md0] 
	pmulhw xmm6, [md0]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm3----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm3
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm4----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm4
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;------------------fin rojos-------------------
	xor rax, rax

	pxor xmm12, xmm12					;xmm10 = 1 | 2 | 3 | 4
	haddps xmm10, xmm12					;xmm10 = 0 | 0| 1+2 | 3+4
	haddps xmm10, xmm12					;xmm10 = 0 | 0 | 0 | 1+2+3+4
	
	movd xmm11, [seiscientos]
	cvtdq2ps xmm11, xmm11
	divss xmm10, xmm11
	cvttss2si eax, xmm10	;convierte single-float_point a dword int y guarda en esi
	mov [r15+r11], al

;YA SE CAMBIO EL PIXEL ACTUAL..

	add r11d, 1
	cmp r11d, r10d
	jg .fin_iteraciones_top
	jmp .iteraciones_top

.fin_iteraciones_top:
	pop r13
	pop r12
	

;indice_actual_bot = ( height - filas_bot )*width*3;
;indice_final_bot = (  (height*width) - (width*2) - 3  )*3;
;---------------------------------------
	xor rdi, rdi
	movd xmm0, edx
	movd xmm1, ecx
	CVTDQ2PS xmm0, xmm0
	CVTDQ2PS xmm1, xmm1
	mulss xmm0, xmm1 			;xmm0 = basura | basura | basura | height*width (float)
	cvtps2dq xmm0, xmm0			;xmm0 = basura | basura | basura | height*width (int)
	movd r10d, xmm0				;r10d = height*width

	mov edi, edx
	add edi, edx				;edi = width*2
	sub r10d, edi
	sub r10d, 3
	mov r11d, r10d
	add r10d, r10d
	add r10d, r11d				;r10d = indice_final_bot

	mov edi, ecx
	sub edi, r13d				;edi = height - filas_bot
	movd xmm0, edi
	movd xmm1, edx
	CVTDQ2PS xmm0, xmm0
	CVTDQ2PS xmm1, xmm1
	mulss xmm0, xmm1			;xmm0 = basura | basura | basura | ( height - filas_bot )*width
	cvtps2dq xmm0, xmm0
	movd r11d, xmm0
	add r11d, 2
	mov edi, r11d
	add r11d, r11d
	add r11d, edi				;r11d = ( height - filas_bot )*width*3 = indice_actual_bot
;---------------------------------------
	
	push r12
	push r13


;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< IT BOT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.iteraciones_bot:
;-------------carga-------------
	xor rdi, rdi

	mov edi, edx
	add edi, edx
	add edi, edx		;edi = width*3

	xor r13, r13
	mov r13d, r11d
	sub r13d, 6

	movdqu xmm2, [r14+r13]
	add r13d, edi

	movdqu xmm3, [r14+r13]
	add r13d, edi

	cmp r11d, r10d
	jne .no_shiftear
	sub r13, 1
	movdqu xmm4, [r14+r13]
	psrldq xmm4, 1
	add r13, 1

.no_shiftear:
	movdqu xmm4, [r14+r13]
	xor r13, r13
	mov r13d, r11d
	sub r13d, 6
	sub r13d, edi

	movdqu xmm1, [r14+r13]
	sub r13d, edi

	movdqu xmm0, [r14+r13]

;
;	xmm0 = ma2_1 | ma2_2 | ma2_3 | ma2_4 | ma2_5 | basura(1byte)
;	xmm1 = ma1_1 | ma1_2 | ma1_3 | ma1_4 | ma1_5 | basura(1byte)
;	xmm2 = ma0_1 | ma0_2 | ma0_3 | ma0_4 | ma0_5 | basura(1byte)
;	xmm3 = me1_1 | me1_2 | me1_3 | me1_4 | me1_5 | basura(1byte)
;	xmm4 = me2_1 | me2_2 | me2_3 | me2_4 | me2_5 | basura(1byte)
;

	pxor xmm10, xmm10
	pxor xmm11, xmm11
;--------------------AZULES---------------------
;---------------------xmm0----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm0
	pshufb xmm5, [mask_btow_b]		;xmm5 = 0 0 0 0 0 0 0 b4 0 b3 0 b2 0 b1 0 b0

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6			;xmm5 = multiplicacion de la parte baja (int dwords)
	punpcklwd xmm5, xmm6			;xmm7 = multiplicacion de la parte alta (int dwords)

	cvtdq2ps xmm5, xmm5 ;(convierte dwords int a floats)
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5				;xmm10 = sumas parciales azules (float 32bits)
	addps xmm10, xmm7

	;Repito lo mismo para las otras 4 lineas de pixeles, para azul:
;---------------------xmm1----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm1
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;---------------------xmm2----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm2
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md0] 
	pmulhw xmm6, [md0]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;---------------------xmm3----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm3
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;---------------------xmm4----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm4
	pshufb xmm5, [mask_btow_b]		

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6	
	punpcklwd xmm5, xmm6	

	cvtdq2ps xmm5, xmm5 
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5	
	addps xmm10, xmm7
;------------------fin azules-------------------
	xor rax, rax

	pxor xmm12, xmm12					;xmm10 = 1 | 2 | 3 | 4
	haddps xmm10, xmm12					;xmm10 = 0 | 0| 1+2 | 3+4
	haddps xmm10, xmm12					;xmm10 = 0 | 0 | 0 | 1+2+3+4
	
	movd xmm11, [seiscientos]
	cvtdq2ps xmm11, xmm11
	divss xmm10, xmm11
	cvttss2si eax, xmm10	;convierte single-float_point a dword int y guarda en esi
	mov [r15+r11], al



	add r11d, 1
	pxor xmm10, xmm10
	pxor xmm11, xmm11

;ahora para los verdes es lo mismo, lo unico que usando la mascara para verdes..
;--------------------VERDES---------------------
;---------------------xmm0----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm0
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm1----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm1
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm2----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm2
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md0] 
	pmulhw xmm6, [md0]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm3----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm3
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm4----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm4
	pshufb xmm5, [mask_btow_g]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;------------------fin verdes-------------------ARREGLADO ESTE!
	xor rax, rax

	pxor xmm12, xmm12					;xmm10 = 1 | 2 | 3 | 4
	haddps xmm10, xmm12					;xmm10 = 0 | 0| 1+2 | 3+4
	haddps xmm10, xmm12					;xmm10 = 0 | 0 | 0 | 1+2+3+4
	
	movd xmm11, [seiscientos]
	cvtdq2ps xmm11, xmm11
	divss xmm10, xmm11
	cvttss2si eax, xmm10	;convierte single-float_point a dword int y guarda en esi
	mov [r15+r11], al

	add r11d, 1
	pxor xmm10, xmm10
	pxor xmm11, xmm11

;--------------------ROJOS----------------------
;---------------------xmm0----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm0
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm1----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm1
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm2----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm2
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md0] 
	pmulhw xmm6, [md0]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm3----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm3
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md1] 
	pmulhw xmm6, [md1]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;---------------------xmm4----------------------
	pxor xmm5, xmm5
	movdqu xmm5, xmm4
	pshufb xmm5, [mask_btow_r]

 	movdqu xmm6, xmm5
	pmullw xmm5, [md2] 
	pmulhw xmm6, [md2]

	movdqu xmm7, xmm5
	punpckhwd xmm7, xmm6
	punpcklwd xmm5, xmm6

	cvtdq2ps xmm5, xmm5
	cvtdq2ps xmm7, xmm7

	addps xmm10, xmm5
	addps xmm10, xmm7
;------------------fin rojos-------------------
	xor rax, rax

	pxor xmm12, xmm12					;xmm10 = 1 | 2 | 3 | 4
	haddps xmm10, xmm12					;xmm10 = 0 | 0| 1+2 | 3+4
	haddps xmm10, xmm12					;xmm10 = 0 | 0 | 0 | 1+2+3+4
	
	movd xmm11, [seiscientos]
	cvtdq2ps xmm11, xmm11
	divss xmm10, xmm11
	cvttss2si eax, xmm10	;convierte single-float_point a dword int y guarda en esi
	mov [r15+r11], al

;ACA YA SE CAMBIO EL PIXEL ACTUAL

	add r11d, 1
	cmp r11d, r10d
	jg .fin_iteraciones_bot
	jmp .iteraciones_bot
	

.fin_iteraciones_bot:

	pop r13
	pop r12

	cmp R9D, R8D
	je .fin_iteraciones

;si hay que seguir iterando:

;filas_top = filas_top - restar_top
;filas_bot = filas_bot - restar_bot

	sub r13d, [restar_bot]
	sub r12d, [restar_top]

;hasta aca anda.


;copiar dst a src: (optimizar para copiar unicamente las bandas modificadas que se perdio la informacion)..
	xor rdi, rdi
	pxor xmm0, xmm0
	pxor xmm1, xmm1
	movd xmm0, edx
	movd xmm1, ecx
	CVTDQ2PS xmm1, xmm1
	CVTDQ2PS xmm0, xmm0
	mulps xmm1, xmm0		;xmm1 = 0|0|0|height*width(float)
	cvtss2si edi, xmm1

	mov esi, edi
	add edi, edi
	add edi, esi			;edi = height*width*3
	sub edi, 16
	;iterar mientras esi sea menor que edi 
	mov esi, 0

.copiar:
	movdqu xmm0, [r15 + rsi]
	movdqu [r14 + rsi], xmm0
	add esi, 16
	cmp esi, edi
	jg .salir_copiar
	jmp .copiar

.salir_copiar:

	add R9D, 1
	jmp .iteraciones

.fin_iteraciones:
	pop RBX
	pop R15
	pop R14
	pop R13
	pop R12
	pop R11
	pop RBP
    ret
