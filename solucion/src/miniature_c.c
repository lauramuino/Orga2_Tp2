/*  topPlane:
        Numero entre 0 y 1 que representa el porcentaje de imagen desde el cual
        va a comenzar la primera iteración de blur (habia arriba)

    bottomPlane:
        Numero entre 0 y 1 que representa el porcentaje de imagen desde el cual
        va a comenzar la primera iteración de blur (hacia abajo)

    iters:
        Cantidad de iteraciones. Por cada iteración se reduce el tamaño de
        ventana que deben blurear, con el fin de generar un blur más intenso
        a medida que se aleja de la fila centro de la imagen.
*/
#include <stdlib.h>
#include <stdio.h>


void miniature_c( unsigned char *src, unsigned char *dst, int width, int height, float topPlane, float bottomPlane, int iters) {
    //guardo la matriz de transformacion:
	float seiscientos = 600;
    int matrizG[25] = {1, 5, 18, 5, 1, 5, 32, 64, 32, 5, 18, 64, 100, 64, 18, 5, 32, 64, 32, 5, 1, 5, 18, 5, 1};

    int filas_top = topPlane*height; //el +1 no se si va.
    int filas_bot = height - bottomPlane*height;

//	int banda_sup = filas_top;
//	int banda_inf = filas_bot;

	float restar_top = filas_top / iters;
	float restar_bot = filas_bot / iters;

    int iteracion_actual = 1;


//copio imagen
    int tam = height*width*3;
    int i;
    for (i = 0;i < tam;i++)
    {
       dst[i]=src[i];
	}


    while(iteracion_actual <= iters)
    {


        //BANDA SUPERIOR
        //ultimo elemento a acceder en la banda superior:
        int pixel_fin_top = (filas_top+1)*width-3;

//		printf("cantfilas de top: %i \n", filas_top);
//		printf("cantfilas de bot: %i \n", filas_bot);
//		printf("termino en el pixel: %i \n", pixel_fin_top);


        int pixel_actual_top = width*2 +2;
        while (pixel_actual_top <= pixel_fin_top)
        {
			float suma_azul = 0;
			float suma_verde = 0;
			float suma_rojo = 0;

            int indice_actual = pixel_actual_top*3;
            int indice_ma2 = indice_actual - 6 - width*2*3;
            int indice_ma1 = indice_actual - 6 - width*3;
            int indice_me0 = indice_actual - 6;
            int indice_me1 = indice_actual - 6 + width*3;
            int indice_me2 = indice_actual - 6 + width*3*2;


            //tomo las 5 lineas alrededor del pixel ..
            unsigned char cercanos[75];
            int i;
            for(i = 0 ;i < 15; i++){
                cercanos[i] = src[i+indice_me2];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+15] = src[i+indice_me1];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+30] = src[i+indice_me0];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+45] = src[i+indice_ma1];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+60] = src[i+indice_ma2];
            }

			//separo por colores..
            unsigned char azules[25];
            unsigned char verdes[25];
            unsigned char rojos[25];

            for(i = 0 ;i < 25; i++){
                azules[i] = cercanos[i*3];
            }
            for(i = 0 ;i < 25; i++){
                verdes[i] = cercanos[i*3+1];
            }
            for(i = 0 ;i < 25; i++){
                rojos[i] = cercanos[i*3+2];
            }

            for(i = 0 ;i < 25; i++){
                suma_azul = suma_azul + (matrizG[i]*azules[i]);
            }

            for(i = 0 ;i < 25; i++){
                suma_verde = suma_verde + (matrizG[i]*verdes[i]);
            }

            for(i = 0 ;i < 25; i++){
                suma_rojo = suma_rojo + (matrizG[i]*rojos[i]);
            }
			suma_azul = suma_azul/seiscientos;
			suma_verde = suma_verde/seiscientos;
			suma_rojo = suma_rojo/seiscientos;
			unsigned char azul_res = suma_azul;
			unsigned char verde_res = suma_verde;
			unsigned char rojo_res = suma_rojo;

			dst[indice_actual]= azul_res;
			dst[indice_actual+1]= verde_res;
			dst[indice_actual+2]= rojo_res;

            pixel_actual_top = pixel_actual_top + 1;
        }//endwhile de TOP

        //BANDA INFERIOR
        int pixel_actual_bot = ( height - filas_bot )*width;
        int ultimo_pixel = (height*width) - (width*2) - 3;

//		printf("primer pixel bot: %i \n", pixel_actual_bot);

        while (pixel_actual_bot <= ultimo_pixel)
        {
            //tomo las 5 lineas alrededor del pixel
			float suma_azul = 0;
			float suma_verde = 0;
			float suma_rojo = 0;

            int indice_actual = pixel_actual_bot*3;
            int indice_ma2 = indice_actual - 6 - width*2*3;
            int indice_ma1 = indice_actual - 6 - width*3;
            int indice_me0 = indice_actual - 6;
            int indice_me1 = indice_actual - 6 + width*3;
            int indice_me2 = indice_actual - 6 + width*3*2;

            //tomo las 5 lineas alrededor del pixel ..
            unsigned char cercanos[75];
            int i;
            for(i = 0 ;i < 15; i++){
                cercanos[i] = src[i+indice_me2];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+15] = src[i+indice_me1];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+30] = src[i+indice_me0];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+45] = src[i+indice_ma1];
            }
            for(i = 0 ;i < 15; i++){
                cercanos[i+60] = src[i+indice_ma2];
            }

			//separo por colores..
            unsigned char azules[25];
            unsigned char verdes[25];
            unsigned char rojos[25];

            for(i = 0 ;i < 25; i++){
                azules[i] = cercanos[i*3];
            }
            for(i = 0 ;i < 25; i++){
                verdes[i] = cercanos[i*3+1];
            }
            for(i = 0 ;i < 25; i++){
                rojos[i] = cercanos[i*3+2];
            }

            for(i = 0 ;i < 25; i++){
                suma_azul = suma_azul + (matrizG[i]*azules[i]);
            }

            for(i = 0 ;i < 25; i++){
                suma_verde = suma_verde + (matrizG[i]*verdes[i]);
            }

            for(i = 0 ;i < 25; i++){
                suma_rojo = suma_rojo + (matrizG[i]*rojos[i]);
            }
			suma_azul = suma_azul/seiscientos;
			suma_verde = suma_verde/seiscientos;
			suma_rojo = suma_rojo/seiscientos;
			unsigned char azul_res = suma_azul;
			unsigned char verde_res = suma_verde;
			unsigned char rojo_res = suma_rojo;

			dst[indice_actual]= azul_res;
			dst[indice_actual+1]= verde_res;
			dst[indice_actual+2]= rojo_res;

            pixel_actual_bot = pixel_actual_bot + 1;
        }//endwhile de BOT

//copiar bandas de arriba y abajo
/*
        int i;
        for (i = 0;i <= banda_sup*width-1;i++)
        {
            src[i]=dst[i];
        }
        for (i = ( height - banda_inf )*width-1; i <= height*width -1;i++)
        {
            src[i]=dst[i];
        }
*/

        //restar filas para prox iteracion:
        filas_top = filas_top - restar_top;
        filas_bot = filas_bot - restar_bot;




        for (i = 0;i <= height*width*3-1;i++)
        {
            src[i]=dst[i];
        }

        iteracion_actual = iteracion_actual +1;

    }//endwhile de iteraciones



}
