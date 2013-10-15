#include <math.h>
#include <stdio.h>

int calcularDistancia(unsigned char* pixel,unsigned char rc,unsigned char gc,unsigned char bc)
{
	int red, green, blue, res;
	long acum;
	int rc_i, gc_i, bc_i;
	double aux;
	red = pixel[2];
	green = pixel[1];
	blue = pixel[0];
	rc_i = rc;
	gc_i = gc;
	bc_i = bc;
	red = red - rc_i;
	//if (red < 0) printf("Rojo negativo %d\n",red);
	red = red*red;
	green = green - gc_i;
	//if (green < 0) printf("Verde negativo %d\n",green);
	green = green*green;
	blue = blue - bc_i;
	//if (blue < 0) printf("Azul negativo %d\n",blue);
	blue = blue*blue;
	acum = red + green + blue;
	aux = acum;
	aux = sqrt(aux);
	res =  ceil(aux);
	return res;
}

void color_filter_c(unsigned char *src,
                    unsigned char *dst,
                    unsigned char rc,
                    unsigned char gc,
                    unsigned char bc,
                    int threshold,
                    int height,
                    int width)
{
	int noFiltrar = 1==0;
	if(noFiltrar){
		int tam_imagen = width*height;
		int pixel_actual = 0;
		while(pixel_actual < tam_imagen){
			dst[pixel_actual*3] = src[pixel_actual*3];
			dst[pixel_actual*3+1] = src[pixel_actual*3+1];
			dst[pixel_actual*3+2] = src[pixel_actual*3+2];
			pixel_actual++;
		}
	}else{
		double aux;
		unsigned char pixel[3];
		int tam_imagen = width*height; 
		long pixel_actual = 0;
		//long pixel_actual = 230*width+ (width-4);
		long indice_actual;
		int canal_actual = 0;
		int distancia, gris,p_x,p_y;
		while(pixel_actual < tam_imagen){
			indice_actual = pixel_actual*3;
			pixel[0] = src[indice_actual];
			pixel[1] = src[indice_actual+1];
			pixel[2] = src[indice_actual+2];
			//Pixel = [B,G,R]
			//printf("Voy por %li\n",indice_actual);
			//p_x = pixel_actual%width;
			//p_y = pixel_actual/width;
			//printf("El pixel (%i,%i)\n",p_x,p_y);
			//printf("El pixel es: (%u,%u,%u)\n",(unsigned int)pixel[0],(unsigned int)pixel[1],(unsigned int)pixel[2]);
			//printf("El pixel es: (%u,%u,%u)\n",(unsigned int)pixel[0],(unsigned int)pixel[1],(unsigned int)pixel[2]);
// 			if(p_x == 957 && p_y == 230){
// 				printf("El pixel (%i,%i)\n",p_x,p_y);
// 				printf("El pixel es: (%u,%u,%u)\n",(unsigned int)pixel[0],(unsigned int)pixel[1],(unsigned int)pixel[2]);
// 				distancia = calcularDistancia(pixel,rc,gc,bc);
// 				//printf("El pixel es: (%u,%u,%u)\n",(unsigned int)pixel[0],(unsigned int)pixel[1],(unsigned int)pixel[2]);
// 				printf("\tDist %d vs Threshold %d)\n",distancia,threshold);
// 			}
			distancia = calcularDistancia(pixel,rc,gc,bc);
			if(distancia > threshold){
				//printf("El pixel (%i,%i) excede el threshold\n",pixel_actual/width,pixel_actual % width);
				//printf("\tDist %d > Threshold %d)\n",distancia,threshold);
				gris = pixel[0] + pixel[1] + pixel[2];
				aux = gris;
				aux = aux/3;
				gris = round(aux);
				for(canal_actual = 0; canal_actual < 3; canal_actual++){
					dst[indice_actual + canal_actual] = gris;
				}
			}
			else{
				dst[indice_actual] = pixel[0];
				dst[indice_actual + 1] = pixel[1];
				dst[indice_actual + 2] = pixel[2];
			}
			pixel_actual++;
		}
	}
}