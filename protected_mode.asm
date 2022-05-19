; iniciamos en 16 bits
bits 16
org 0x7c00

boot:
    ; enable A20 bit
    mov ax, 0x2401
    int 0x15

    ; set vga to be normal mode
    mov ax, 0x3
    int 0x10

    cli                             ; Deshabilitamos las interrupciones, ya no podemos usarlas como antes para interactuar con la BIOS
    lgdt [gdt_pointer]              ; Cargamos la GDT

    mov eax, cr0                    ; Modificamos el ultimo bit del registro CR0 (PE) a 1 para habilitar el modo protegido
    or eax,0x1                        
    mov cr0, eax                    
    jmp CODE_SEG:boot2              

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
gdt_start:
    dq 0x0 ; inicializamos 8 bytes en 0, condición impuesta por el fabricante
gdt_code:
    dw 0xffff ; límite
    dw 0x0  ; base (16 bits)
    db 0x0  ; base (8 bits) : (16 + 8 = 24 bits)
    db 0b10011010   ; pres, priv, type, type flags, other flags
    db 0b11001111   ; other flags, limit (ultimos 4 bits, en total son 20)
    db 0x0  ; ultimos 8 bits de la base (32 bits)
gdt_data:
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
gdt_end:
gdt_pointer:
    dw gdt_end - gdt_start-1    ; tamaño
    dd gdt_start                ; puntero al inicio de la GDT

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

bits 32

boot2:
    ; DATA_SEG es el offset relativo a la gdt --> es decir, el selector.
    ; carga los selectores a los registros de segmento
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esi,hello   ; carga el mensaje "hello world" al registro de propósito general
    mov ebx,0xb8000 ; ya no tenemos interrupciones y tenemos que escribir directamente en videoMemory (empieza en 0xB8000)

.loop:
    lodsb                           ; carga la string de [DS:SI] a AL
    or al,al                        ; 
    jz halt                         ; las dos lineas de arriba son equivalentes a decir CMP AL, 0 JE halt
    or eax,0x0F00                   ; configuramos el color para que sea blanco  [4bit bg color][4bit text color][8bit ascii]
                                    ; mas informacion sobre los colores: https://en.wikipedia.org/wiki/Video_Graphics_Array#Color_palette
    mov word [ebx], ax      ; ingresamos el color y el buffer
    add ebx,2                       ; incrementamos ebx por dos bytes (1byte por color, 1byte por ASCII)
    jmp .loop
halt:
    cli
    hlt
hello: db "Hello world!",0

times 510 - ($-$$) db 0
dw 0xaa55