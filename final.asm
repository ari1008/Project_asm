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
image_x:        resd    1
image_y:        resd    1
c_r:            resd    1
c_i:            resd    1
i:              resd    1
tmp:            resd    1
result:         resd    1
iteration_max:  resd    1
z_r:            resd    1
z_i:            resd    1
teste: resd 1


section .data

event:		times	24 dq 0

x1:	dd	-2.1
x2:	dd	0.6
y1:	dd	-1.2
y2:	dd	1.2
zoom:   dd      100
x:      dd        0
y:      dd        0
zero:    dd       0
un:      dd       1
deux:    dd       2
quatre:  dd       4
format:  db       "On passe dans la boucle: %f",10,0
format1:  db      "On passe dans la boucle: %d",10,0 



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
movss xmm1,dword[x2]
movss xmm2,dword[x1]
movss xmm3,dword[zoom]
subss xmm1,xmm2
mulss xmm3,xmm1
cvtss2si eax,xmm3
mov dword[image_x],eax
xorps xmm3,xmm3
xorps xmm1,xmm1
xorps xmm2,xmm2


movss xmm0,dword[y1]
movss xmm1,dword[y2]


subss xmm1,xmm0
mulss xmm2,dword[zoom]
cvtss2si ebx,xmm2
mov dword[image_y],ebx

;Rénitialiser eax,ebx,xmm0,xmm1,xmm2
xor eax,eax
xor ebx,ebx
xorps xmm0,xmm0
xorps xmm1,xmm1
xorps xmm2,xmm2


for1:

        cmp eax,dword[image_x] ; x>=image_x
        jae flush
        
for2: 
        xor eax,eax
        mov eax,dword[y]
        cmp eax,dword[image_y] ; y>=image_y
        jae vfor
        
        ; Calcule de c_r = x / zoom + x1

        xorps xmm0,xmm0
        
        movss xmm0,dword[x]
        movss xmm1,dword[zoom]
        divss  xmm0,xmm1
        addss xmm0,dword[x1]
        movss dword[c_r], xmm0
        
        ;remise a zéro
        xorps xmm0,xmm0
        xorps xmm1,xmm1
        
        
        
        ; Calcule de c_i = y / zoom + y1
        movss xmm0,dword[y]
        movss xmm1,dword[zoom]
        divss xmm0,xmm1
        addss xmm0,dword[y1]
        movss dword[c_i], xmm0
        
        ;remise a zéro
        xorps xmm0,xmm0
        xorps xmm1,xmm1
        
        ; Mettre a zéro z_r et z_i  et i
        movss xmm0,dword[zero]
        movss dword[z_r],xmm0
        movss dword[z_i],xmm0
        movss dword[i],xmm0
        
        ;remise a zéro
        xorps xmm0,xmm0

todo:
    ;remise a zéro
    xorps xmm0,xmm0
    xorps xmm1,xmm1
    
    
    movss xmm0,dword[z_r]
    movss xmm1,dword[z_r]
    movss dword[tmp], xmm0
    
    ;Calcul z_r = z_r*z_r - z_i*z_r + c_r
    mulss xmm0,dword[z_r]
    mulss xmm1,dword[z_i]
    subss xmm0,xmm1
    addss xmm0,dword[c_r]
    movss dword[z_r],xmm0
        
    ;Rénitialiser de xmm0
    xorps xmm0,xmm0
        
                   
    ;Calcul z_i = 2 * z_i * tmp + c_i
     movss xmm0,dword[deux]
     mulss xmm0,dword[z_i]
     mulss xmm0, dword[tmp]
     addss  xmm0, dword[c_i]
     movss dword[z_i],xmm0
        
    ;Rénitialiser de xmm0
     xorps xmm0,xmm0
        
    ;incrémention de +1 sur i
     mov eax,dword[un]
     add dword[i],eax
     
     ;Rénitialiser de xmm0
     xorps xmm0,xmm0
     xor eax,eax
     
    ;Calcul de z_r*z_r + z_i*z_i dans result
    movss xmm0,dword[z_r]
    mulss xmm0,dword[z_r]
    movss xmm1,dword[z_i]
    mulss xmm0,dword[z_i]
    addss xmm0,xmm1
    
    ;Rénitialiser de xmm1
    xorps xmm1,xmm1
    
    ;Mettre i dans xmm1
    movss xmm1,dword[i]

     
     
     comiss xmm0,dword[quatre] ; result >= 4
     jae todo
     comiss xmm1,dword[iteration_max] ; i>iteration_max
     ja todo
     comiss xmm1,dword[iteration_max] ; i=/=iteration_max
     jne for2


pixel: 
          ; dessin de la ligne 1
          mov rdi,qword[display_name]
          mov rsi,qword[window]
          mov rdx,qword[gc]
          mov ecx,dword[x]	; coordonnée source en x
          mov r8d,dword[y]	; coordonnée source en y
          mov r9d,dword[x]	; coordonnée destination en x
          push qword[y]		; coordonnée destination en y
          call XDrawLine
          inc dword[y]
          jmp for2
        
        
        
        
vfor:
    ;Rénitialiser de xmm0
     xor eax,eax
    inc dword[x]
    mov ecx,0
    mov dword[y],ecx
    xor ecx,ecx
    jmp for1

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
	
