#include <math.h>

int calcularDistancia(unsigned char* pixel,unsigned char rc,unsigned char gc,unsigned char bc)
{
	int red, green, blue, res;
	red = pixel[0];
	green = pixel[1];
	blue = pixel[2];
	red = red - rc;
	red = red*red;
	green = green - gc;
	green = green*green;
	blue = blue - bc;
	blue = blue*blue;
	res = red + green + blue;
	res = sqrt(res);
	return res;
}

void color_filter_c(unsigned char *src,
                    unsigned char *dst,
                    unsigned char rc,
                    unsigned char gc,
                    unsigned char bc,
                    int threshold,
                    int width,
                    int height)
{
	unsigned char pixel[3];
	int tam_imagen = width*height;
	int pixel_actual = 0;
	int canal_actual = 0;
	int distancia, gris;
	while(pixel_actual < tam_imagen){
		for(canal_actual = 0; canal_actual < 3; canal_actual++){
			pixel[canal_actual] = src[pixel_actual*3 + canal_actual];
		}
		distancia = calcularDistancia(pixel,rc,gc,bc);
		if(distancia > threshold){
			gris = pixel[0] + pixel[1] + pixel[2];
			gris = gris/3;
			for(canal_actual = 0; canal_actual < 3; canal_actual++){
				dst[pixel_actual*3 + canal_actual] = gris;
			}
		}
		else{
			for(canal_actual = 0; canal_actual < 3; canal_actual++){
				dst[pixel_actual*3 + canal_actual] = src[pixel_actual*3 + canal_actual];
			}
		}
		pixel_actual++;
	}
}