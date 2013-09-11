#include <stdio.h>

void decode_c(unsigned char* src,
              unsigned char* code,
			  int size,
              int width,
              int height)
{
// src = imagen de entrada: puntero al inicio de la matrix de elementos de 24 bits sin signo (BGR)
// code = puntero a un arreglo de caracteres para el mensaje decodificado de la imagen

// width y heigh = ancho y alto en pixeles de la imagen

    int p = 0;
    int tam = width*height*3;
    unsigned char loscuatro[4];
    unsigned char caracter;
    int pcode = 0;
    while(p<64)
    {
        caracter = 0;
        int i;

        for(i = 0;i<4;i++)
        {
            loscuatro[i] = src[i+p];
            
        }  
        for(i = 0;i<4;i++) 
        {
            caracter = caracter << 2;
            unsigned char parte = 3&loscuatro[i];
            unsigned char mod = 12&loscuatro[i];     
            switch(mod)
            {
                case 0: break;
                case 4: parte = (parte +1) % 4 ;
                         break;
                case 8: parte = (parte -1) % 4 ;
                         break;
                case 12: parte = (~parte) % 4;
                        break;
            }
            parte = parte & 3;
            caracter = caracter + parte;
            printf("Caracter: %d \n",(unsigned int)caracter);
        }
        printf("Caracter final: %d \n",(unsigned int)caracter);
        code[pcode] = caracter;
        pcode++;
        p = p + 4;
    }
    //code[pcode] = 0;
    
}





