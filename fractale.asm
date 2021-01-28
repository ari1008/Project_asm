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
x1:             resd    1
x2:             resd    1
y1:             resd    1
y2:             resd    1
section .data

event:		times	24 dq 0

;x1:	dd	0
;x2:	dd	0
;y1:	dd	0
;y2:	dd	0

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
	
movsd dword[x1],-2.1
movsd dword[y1],-1.2
movsd dword[x2],0.6
movsd dword[y2],1.2

movsx ebx,dword[x2]
movsx eax,dword[x1]

fsub ebx,eax
fmul ebx,dword[zoom]
;lea ebx, [ebx * dword[zoom]]

movsx dword[image_x],dword[ebx]

movsx ecx,dword[y1]
movsw edx,dword[y2]


fsub edx,ecx
fmul edx,dword[zoom]
;lea ebx, [ebx * dword[zoom]]

movsx dword[image_y],dword[edx]

xor eax,eax;eax = 0
xor ebx,ebx;ebx = 0
xor ecx,ecx;ecx = 0
xor edx,edx;edx = 0

;pour x = 0 tant que x < image_x step 1
;pour y = 0 tant que y < image_y stpe 1
    
boucleX:
        cmp x,image_x
        jl flush
        cmp y,image_y
        jl todo
        jmp boucleX

todo:
        ; Calcule de c_r = x / zoom + x1
        movsx eax,dword[x]
        movsx ebx,dword[zoom]
        cwd 
        idiv ebx
        add ebx,dword[x1]
        movsx c_r, dword[ebx]
        
        ;Remise a zéro de ces registres ebx et eax
        xor ebx,ebx
        xor eax, eax
        
        ; Calcule de c_i = y / zoom + y1
        movsx eax,dword[y]
        movsx ebx,dword[zoom]
        cwd
        idiv ebx
        add ebx,dword[y1]
        movsx c_i, dword[ebx]

        ;Remise a zéro de ces registres ebx et eax
        xor ebx,ebx
        xor eax, eax   
        
        ; Mettre a zéro z_r et z_i  et i
        mov z_r,0
        mov z_i,0 
        mov i,0

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
	