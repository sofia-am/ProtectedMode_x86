%macro PUSH_EADX 0
    push eax
    push ebx
    push ecx
    push edx
%endmacro

%macro POP_EDAX 0
    pop edx
    pop ecx
    pop ebx
    pop eax
%endmacro

[org 0x7c00]   ; arranca en 0x7C00     

message db "hello world", 0
vga_current_line dd 0
mov [BOOT_DISK], dl    

; lo primero que tenemos que definir es el tamaño y la ubicación de nuestros segmentos
; para eso definimos:
; - base: describe dónde empieza nuestro segmento
; - limit: descibe el tamaño del segmento
; - present: 1 si se usa para segmentos
; - privilege: 0 a 3, implementa mecanismos de seguridad
; - type: define si es código o datos
; flags: (CODE SEGMENT)
;   - type flags: 
;       - code?
;       - conforming: puede ejecutarse con niveles de privilegio menores?
;       - readable: puede ser leible o solo ejecutable?
;       - accessed: se setea a 1 por la CPU cuando se lo accede
;   - other flags:
;       - granularity: multiplica el limite por 0x1000, podemos usar 1 GB de memoria
;       - 32 bits: usa 32 bits? 
;       - AVL (no usamos)
; flags: (DATA SEGMENT)
;   - type flags:
;       - code?
;       - direction: el segmento crece hacia abajo 1
;       - writable: 0 si es read only
;
CODE_SEG equ GDT_code - GDT_start
DATA_SEG equ GDT_data - GDT_start

cli ; deshabilitamos las interrupciones, ya no podemos usarlas como antes para interactuar con la BIOS
lgdt [GDT_descriptor]   ; cargamos la GDT
mov eax, cr0    
or eax, 1   
mov cr0, eax    ; seteamos el ultimo bit (PE) de CR0 a 1 para habilitar el modo protegido
jmp CODE_SEG:start_protected_mode

;jmp $                        
                                     
GDT_start:
    GDT_null: ; inicializamos 8 bytes en 0, condición impuesta por el fabricante
        dd 0x0
        dd 0x0

    GDT_code:
        dw 0xffff ; límite
        dw 0x0  ; base (16 bits)
        db 0x0  ; base (8 bits) : (16 + 8 = 24 bits)
        db 0b10011010   ; pres, priv, type, type flags, other flags
        db 0b11001111   ; other flags, limit (ultimos 4 bits, en total son 20)
        db 0x0  ; ultimos 8 bits de la base (32 bits)

    GDT_data:
        dw 0xffff
        dw 0x0
        db 0x0
        db 0b10010010
        db 0b11001111
        db 0x0

GDT_end:

GDT_descriptor:
    dw GDT_end - GDT_start - 1 ; tamaño
    dd GDT_start    ; puntero al inicio de la GDT

[bits 32]
start_protected_mode: ; ya no tenemos interrupciones y tenemos que escribir directamente en videoMemory (empieza en 0xB8000)
    ; DATA_SEG es el offset relativo a la gdt --> es decir, el selector.
    ; carga los selectores a los registros de segmento aaaa
    mov ax, DATA_SEG
    mov ds, ax 
    mov es, ax 
    mov fs, ax 
    mov gs, ax
    mov ss, ax
    ; define los punteros base pointer y stack pointer
    mov ebp, 0x7c00
    mov esp, ebp
    
    PUSH_EADX
    ; carga el mensaje "hello world" al registro de uso general ecx
    mov ecx, $message
    mov eax, $vga_current_line
    mov edx, 0
    mov ebx, 25 ; cantidad de lineas horizontales ?¿
    div ebx 
    mov eax, edx 
    mov edx, 160 ; 160 = 80*2 = line width * bytes per character on screen
    mul edx 
    lea edx, [eax + 0xb8000] ;load effective address destination, source
    mov ah, 0x0F ;color

loop:
    mov al, [ecx] ; recorremos el array de "hello world"
    cmp al, 0 ; si es 0 (null character, termino el string), salgo
    je end
    mov [edx], ax ; creo que edx es lo que printea en pantalla
    inc ecx 
    add edx, 2
    jmp loop

end:
    mov al, [vga_current_line]
    inc al
    mov [vga_current_line], al
    POP_EDAX
    
BOOT_DISK: db 0                            

times 510-($-$$) db 0              
dw 0xaa55
