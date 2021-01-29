; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main

section .bss
display_name:	resq	1
screen:	        resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1
image_x:        resq    1
image_y:        resq    1
c_r:            resq    1
c_i:            resq    1
z_r:            resq    1
z_i:            resq    1
i:              resq    1
tmp:            resq    1
result:         resq    1
iteration_max:  resq    1


section .data

event:		times	24 dq 0

x1:	dd	-2.1
x2:	dd	0.6
y1:	dd	-1.2
y2:	dd	1.2
zoom:   dd      100
x:      dd        0
y:      dd        0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:
	


movss xmm0,dword[x2]
movss xmm1,dword[x1]

subss xmm0,xmm1
mulss xmm2,dword[zoom]


movss dword[image_x],xmm2
xorps xmm0,xmm0
xorps xmm1,xmm1
xorps xmm2,xmm2

movss xmm0,dword[y1]
movss xmm1,dword[y2]


subss xmm1,xmm0
mulss xmm2,dword[zoom]


movss dword[image_y],xmm2
xorps xmm0,xmm0
xorps xmm1,xmm1
xorps xmm2,xmm2




;pour x = 0 tant que x < image_x step 1
;pour y = 0 tant que y < image_y stpe 1
    
boucleX:
        mov eax,dword[x]
        cmp eax,dword[image_x]
        jl flush
        mov ebx,dword[y]
        cmp ebx,dword[image_y]
        jl todo
        jmp boucleX

todo:
        ; Calcule de c_r = x / zoom + x1
        xor eax,eax
        xor ebx,ebx
        mov eax,dword[x]
        mov ebx,dword[zoom]
        xor edx,edx
        div  ebx
        add eax,dword[x1]
        movss dword[c_r], eax
        
        ;remise a zéro
        xor eax,eax
        xor ebx,ebx
        xor edx,edx
        
        
        ; Calcule de c_i = y / zoom + y1
        mov eax,dword[y]
        mov ebx,dword[zoom]
        xor edx,edx
        div ebx
        add eax,dword[y1]
        mov c_i, dword[eax]

        ;Remise a zéro de ces registres ebx et eax
        xor ebx,ebx
        xor eax, eax
        xor edx,edx   
        
        ; Mettre a zéro z_r et z_i  et i
        xor z_r,z_r
        xor z_i,z_i 
        xor i,i

calcul:
    mov tmp, z_r
    
    ;Calcul z_r = z_r*z_r - z_i + c_r
    imul eax, dword[z_r],dword[z_r]
    sub z_r,dword[eax]
    add z_r,dword[c_r]
        
    ;Rénitialiser de eax
    xor eax,eax
        
                   
    ;Calcul z_i = 2 * z_i * tmp + c_i
     imul eax, 2, dword[z_i]
     imul eax, dword[tmp]
     add  eax, dword[c_i]
     movzx dword[z_i],dword[eax]
        
    ;Rénitialiser de eax
     xor eax,eax
        
    ;incrémention de +1 sur i
     inc i 
     
    ;Calcul de z_r*z_r + z_i dans result
    imul eax, dword[z_r], dword[z_r]
    add eax,dword[z_i]
    mov dword[result],dword[eax]

    ;Rénitialiser de eax
     xor eax,eax
    
    ;Boucle calcul relancer si i< iteration_max
    cmp dword[i],dword[iteration_max]
    jl calcul
    
    ;Boucle calcul relancer si result < 4
     cmp dword[result],4
     jl calcul
     
     ;Sautez la boucle dessin si jamais i=/= iteration_max
     cmp dword[i],dword[iteration_max]
     jne saut
     
pixel:
      ; dessiner le pixel de cordonnées (x;y)  
        mov rdi,qword[display_name]
        mov rsi,qword[gc]
        mov edx,0xFF0000	; Couleur du crayon ; rouge
        call XSetForeground
        ; dessin du pixel
        mov rdi,qword[display_name]
        mov rsi,qword[window]
        mov rdx,qword[gc]
        mov ecx,dword[x1]	; coordonnée source en x
        mov r8d,dword[y1]	; coordonnée source en y
        mov r9d,dword[x2]	; coordonnée destination en x
        push qword[y2]		; coordonnée destination en y
        call XDrawLine
        
saut:
     jmp boucleX  

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	