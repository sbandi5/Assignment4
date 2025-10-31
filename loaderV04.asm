org 0x3456

    mov ax, cs
    mov ds, ax

    ; Draw left vertical border
    mov si, vert
    mov cx, vertlen
    mov dl, 29
    mov bl, 07h
    mov dh, 9
print_left_border:
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    inc dh
    cmp dh, 14
    jl print_left_border

    ; Load logo sector into 0000:007e
    mov bx, 0x0000
    mov es, bx
    mov bx, 0x007e
    mov ah, 02h
    mov al, 1
    mov ch, 1
    mov cl, 15
    mov dh, 0
    mov dl, 0
    int 13h

    ; Print logo lines from loaded buffer
    push ds
    xor ax, ax
    mov ds, ax
    mov si, 0x007e
    mov cx, 24
    mov bl, 0x0E
    mov dh, 9
    mov dl, 30
    ; Clear a black rectangle behind the logo (rows 9-13, cols 30-53)
    mov bh, 0x00    ; attribute: black on black
    mov ch, 9
    mov cl, 30
    mov dh, 13
    mov dl, 53
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0404]
    pop es
    pop ax
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    add si, 26
    inc dh
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    add si, 26
    inc dh
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    add si, 26
    inc dh
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    add si, 26
    inc dh
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    pop ds

	; Print top border
    mov si, topborder
    mov cx, topborderLen
    mov bl, 07h
    mov dh, 8
    mov dl, 29
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax

	; Print bottom border
    mov si, bottomborder
    mov cx, bottomborderLen
    mov bl, 07h
    mov dh, 14
    mov dl, 29
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax

    ; Draw right vertical border
    mov si, vert
    mov cx, vertlen
    mov dl, 53
    mov bl, 07h
    mov dh, 9
print_right_border:
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax
    inc dh
    cmp dh, 14
    jl print_right_border
    
    ; Print main message
    mov si, wmsg
    mov cx, wlen
    mov bl, 25h
    mov dh, 20
    mov dl, 19
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax

	; Print main message again (original behaviour)
    mov si, wmsg
    mov cx, wlen
    mov bl, 25h
    mov dh, 20
    mov dl, 19
    push ax
    push es
    xor ax, ax
    mov es, ax
    call far [es:0x0400]
    pop es
    pop ax

    ;;;load 3rd sector to load data
    mov bx, 0x0002			;es:bx input buffer, temporary set 0x0002:3656
    mov es, bx
    mov bx, 0x3656
    mov ah, 02h				;Function 02h (read sector)
    mov al, 1				;Read one sector
    mov ch, 0				;Cylinder#
    mov cl, 7				;Sector# where program is located
    mov dh, 0				;Head# --> logical sector 1
    mov dl, 0				;Drive# A, 08h=C
	int 13h

    push cs
    push word return_from_dateTime
    jmp word 0x0002:0x3656

return_from_dateTime:
    pop bx
    pop ax
    mov [loader_return_ptr], bx        ; offset
    mov [loader_return_ptr+2], ax      ; segment
    jmp far [loader_return_ptr]




   

msg db 'Sai OS, version 1.0 (c) Sep 2025 ...',
mlen equ $-msg

wmsg db 'Welcome to Sai os, Press any key to Continue...'
wlen equ $-wmsg

msg1 db 0x0D, 0x0A, '$'
mlen1 equ $-msg1

topborder db 201,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,187
topborderLen equ $-topborder

bottomborder db 200,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,188
bottomborderLen equ $-bottomborder

vert db 186
vertlen equ $-vert

loader_return_ptr dw 0,0
