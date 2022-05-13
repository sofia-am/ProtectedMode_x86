; compilar con: nasm -f bin keyboard_input.asm -o boot.bin   
; abrir en qemu con: qemu-system-x86_64 boot.bin


[org 0x7c00] ; seteamos el offset desde la direccion 0x7C00

; je: jump if equal
; int 0x10: muestra 1 caracter en pantalla
; int 0x16: toma un caracter del teclado

string db "Ingrese de 0 a 10 caracteres ", 0xd, 0xa, "Presione Enter para confirmar: ", 0xd, 0xa, 0
buffer times 10 db 0
	db 0;null
mov ah, 0x0e ; teletype mode
mov bx, string

printbx: ; printea el buffer
	mov al, [bx]
	cmp al, 0
	je printbxexit
	int 0x10
	inc bx ; bx nuestro puntero que recorre el buffer
	jmp printbx

printbxexit:
    mov bx, buffer ;carga buffer al registro bx

    ;exit si el buffer es 0
    mov cx, [bx]
    cmp cx, 0
    jne exit

    mov cx, 10 

read:
	; lee un caracter del teclado, se almacena en al
	mov ah, 0
	int 0x16

	cmp al, 0xd; compara a tecla Enter
	je enter

	cmp al, 8; compara a tecla Backspace (retroceso)
	je backspace

	; chequea si la entrada es válida (termina con un caracter nulo)
	cmp cx, 0
	je read

	; muestra el caracter ingresado
	mov ah, 0x0e
	int 0x10

	; lo almacena en el buffer
	mov [bx], al
	inc bx

	; setea el contador y repite todo de nuevo
	dec cx
	jmp read

backspace:
	; si no se ingresó nada antes, no hace nada
	cmp cx, 10
	je read 

	inc cx

	; borra el ultimo caracter del buffer 
	dec bx
	mov ah, 0x0e
	int 0x10
	mov al, 0 
	mov [bx], al
	int 0x10
	mov al, 8
	int 0x10

	jmp read

enter:
	; printea un salto de linea
	mov ah, 0xe
	mov al, 0xd
	int 0x10
	mov al, 0xa ; 0xA = /n
	int 0x10

	; printea el buffer
	mov bx, buffer
	jmp printbx

exit:
    ; printea un salto de linea
    mov al, 0xd
    int 0x10
    mov al, 0xa
    int 0x10

    jmp read

times 510-($-$$) db 0 
db 0x55, 0xaa

; times repite una accion cierta cantidad de veces: 
; db 0 -> define byte 0
; ($-$$) = (current address - section start) = length of previous code
; previous code + (510 - previous code) = 510
; 510 + 0x55 + 0xAA = 512 bytes