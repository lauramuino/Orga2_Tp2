global decode_asm

section .data


section .text
;void decode_asm(unsigned char *src,
;              unsigned char *code,
;              int width,
;              int height);

decode_asm:
	;Mover a xmm0 16 bytes de imagen
	;Extraer de cada uno el code
	;Extraer de cada uno el op
	;De acuerdo con el op, modificar el code.
	;Extrar los 4 bytes de caracteres.
	;insertarlos en RSI y avanzar RDI += 16, RSI += 4
	;Repetir si ninguno de los caracteres es 0. O parar si todos son 0.
	;Fin feliz.
    ret
