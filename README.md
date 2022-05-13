Universidad Nacional de Córdoba - Facultad de Ciencias Exactas, Físicas y Naturales
# Sistemas de Computación - Trabajo Practico #3

Para compilar los ejemplos:

    nasm -f bin <nombre-del-archivo-asm> -o <nombre-del-binario>

Para correrlos en el entorno virtual QEMU:
    
    qemu-system-x86_64 <nombre-del-binario>


## Modo Real
El archivo `keyboard_input.asm` utiliza las interrupciones que brinda la BIOS para tomar caracteres del teclado e imprimirlos en pantalla.

## Modo Protegido
El archivo `protected_mode.asm` en cambio se ejecuta en modo protegido. Para esto comienza deshabilitando las interrupciones y generando una GDT (Global Descriptor Table) con un segmento de datos y uno de código.

Luego aprovecha el video memory register para imprimir en pantalla un mensaje, utilizando para ello los registros de propósito general. 
