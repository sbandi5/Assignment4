org 0x3456

    mov ax, cs
    mov ds, ax

    ; Draw left vertical border
    mov si, vert
    mov cx, vertlen
    mov dl, 29
    mov bl, 7Ah
    mov dh, 9
print_left_border:
    call print_string
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
    call print_string
    add si, 26
    inc dh
    call print_string
    add si, 26
    inc dh
    call print_string
    add si, 26
    inc dh
    call print_string
    add si, 26
    inc dh
    call print_string
    pop ds

	; Print top border
    mov si, topborder
    mov cx, topborderLen
    mov bl, 7Ah
    mov dh, 8
    mov dl, 29
    call print_string

	; Print bottom border
    mov si, bottomborder
    mov cx, bottomborderLen
    mov bl, 7Ah
    mov dh, 14
    mov dl, 29
    call print_string

    ; Draw right vertical border
    mov si, vert
    mov cx, vertlen
    mov dl, 53
    mov bl, 7Ah
    mov dh, 9
print_right_border:
    call print_string
    inc dh
    cmp dh, 14
    jl print_right_border
    
    ; Print main message
    mov si, wmsg
    mov cx, wlen
    mov bl, 25h
    mov dh, 20
    mov dl, 19
    call print_string

	; Print main message again (original behaviour)
    mov si, wmsg
    mov cx, wlen
    mov bl, 25h
    mov dh, 20
    mov dl, 19
    call print_string

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

;;print string helper
;;  DS:SI = text pointer, CX = length, BL = attribute, DH/DL = row/col
print_string:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es

	mov ax, 0xb800
	mov es, ax

	call calc_offset

	or cx, cx
	jz print_string_done

	cld
print_string_loop:
	lodsb
	cmp al, 0x0D
	je print_string_cr
	cmp al, 0x0A
	je print_string_lf
	mov ah, bl
	stosw
	inc dl
	jmp short print_string_next

print_string_cr:
	mov dl, 0
	call calc_offset
	jmp short print_string_next

print_string_lf:
	inc dh
	call calc_offset
	jmp short print_string_next

print_string_next:
	loop print_string_loop

print_string_done:
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

calc_offset:
	push ax
	xor ax, ax
	mov al, dh
	mov di, ax
	shl di, 4
	mov ax, di
	shl ax, 2
	add di, ax
	xor ax, ax
	mov al, dl
	add di, ax
	shl di, 1
	pop ax
	ret


   

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
