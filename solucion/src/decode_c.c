void decode_c(unsigned char* src,
              unsigned char* code,
			  int size,
              int width,
              int height)
{
// src = imagen de entrada: puntero al inicio de la matrix de elementos de 24 bits sin signo (RGB)
// code = puntero a un arreglo de caracteres para el mensaje decodificado de la imagen
// size = cantidad de caracteres del msje.
// width y height = ancho y alto en pixeles de la imagen

    unsigned int p = 0;
    unsigned int cantValores = width*height*3;
    unsigned char loscuatro[4];
    unsigned char caracter = 1;
    unsigned int pcode = 0;
    while(size != 0)
    {
		//printf("Iteracion %d \n",p);
        caracter = 0;
        unsigned int i;
        for(i = 0;i<4;i++)
        {
            loscuatro[i] = src[p + i];
			//printf("%u \n",(unsigned int)loscuatro[i]);
            
        }  
        for(i = 0;i<4;i++) 
        {
            caracter = caracter << 2;
			unsigned char parte = 3 & loscuatro[3-i];
            unsigned char mod = 12 & loscuatro[3-i];
			mod = mod >> 2;
			//printf("Code: %u Op: %u \n",(unsigned int)parte,(unsigned int)mod);
			
            switch(mod)
            {
                case 0: break;
                case 1: parte = (parte +1) % 4 ;
                         break;
                case 2: parte = (parte -1) % 4 ;
                         break;
                case 3: parte = (~parte) % 4;
                        break;
            }
            parte = 3 & parte;
            caracter = caracter + parte;
			//printf("Code resultante: %u \n",(unsigned int)parte);
        }
        //printf("Caracter final: %c \n", caracter);
		code[pcode] = caracter;
		//printf("En la posicion: %u \n", pcode);
		pcode++;
        p = p + 4;
		size--;
    }
}
