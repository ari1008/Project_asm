# Project_asm
Dessin d'une fractale en asm 64 bits

Algo de la fractale: 
// on définit la zone que l'on dessine. Ici, la fractale toute entière
définir x1 = -2.1
définir x2 = 0.6
définir y1 = -1.2
définir y2 = 1.2
définir zoom = 100 // pour une distance de 1 sur le plan, on a 100 pixels sur l'image
définir iteration_max = 50
// on calcule la taille de l'image :
définir image_x = (x2 - x1) * zoom
définir image_y = (y2 - y1) * zoom
Pour x = 0 tant que x < image_x par pas de 1
    Pour y = 0 tant que y < image_y par pas de 1
        définir c_r = x / zoom + x1
        définir c_i = y / zoom + y1
        définir z_r = 0
        définir z_i = 0
        définir i = 0

        Faire
            définir tmp = z_r
            z_r = z_r*z_r - z_i*z_i + c_r
            z_i = 2*z_i*tmp + c_i
            i = i+1
        Tant que z_r*z_r + z_i*z_i < 4 et i < iteration_max

        si i = iteration_max
            dessiner le pixel de coordonnées (x; y)
        finSi
        inc y
    finPour
    inc x
finPour


