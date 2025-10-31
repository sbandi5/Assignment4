;datetimeV03.asm - Date and Time Display with Keypress
;To be loaded at memory location 0002:3656 (sector 6)
org 0x3656

start:
    ; Initialize segments
    push cs
    pop ds
    push cs
    pop es

    ;mov bx, 0x0002			;es:bx input buffer, temporary set 0x0001:1234
	;mov es, bx

    ; Macro to convert BCD to ASCII and store in buffer
%macro makedt 4
	mov bh,%1 			;dh/dl/chcl
	shr bh,4
    add bh,30h 			;add 30h to convert to ascii
	mov [%2 + %3],bh
	mov bh,%1
	and bh,0fh
	add bh,30h
	mov [%2 + %4],bh
%endmacro

    ; Macro to display a string
    ; Get current date
    mov ah,04h	         ;function 04h (get RTC date)
    int 1Ah		         ;BIOS Interrupt 1Ah (Read Real Time Clock)
    jnc date_ok          ;If no error, continue

    ; If error, use hardcoded date
    mov ch, 0x20         ; Century 20
    mov cl, 0x25         ; Year 25
    mov dh, 0x02         ; Month 02
    mov dl, 0x27         ; Day 27

date_ok:
    ; CH - Century, CL - Year, DH - Month, DL - Day
    makedt dh, dtfld, 0, 1
    makedt dl, dtfld, 3, 4
    makedt ch, dtfld, 6, 7
    makedt cl, dtfld, 8, 9
    
    ; Display date label
    mov si, dlabel
    mov cx, 5
    mov bl, 0Ah        ; Light Green
    mov dh, 2          ; Row 2 (near top)
    mov dl, 58         ; Column 58 (right side)
    call print_string
    
    ; Display date value
    mov si, dtfld
    mov cx, 10
    mov bl, 0Ah        ; Light Green
    mov dh, 2          ; Row 2
    mov dl, 65         ; Column 65 (right after label)
    call print_string

    ; Get current time
    mov ah,02h
    int 1Ah
    jnc time_ok         ;If no error, continue

    ; If error, use hardcoded time
    mov ch, 0x12         ; Hours 12
    mov cl, 0x00         ; Minutes 00
    mov dh, 0x00         ; Seconds 00

time_ok:
    ; CH - Hours, CL - Minutes, DH - Seconds
    makedt ch, tmfld, 0, 1
    makedt cl, tmfld, 3, 4
    makedt dh, tmfld, 6, 7
    
    ; Display time label
    mov si, tlabel
    mov cx, 5
    mov bl, 0Ah        ; Light Green
    mov dh, 3          ; Row 3 (just below date)
    mov dl, 58         ; Column 58 (right side)
    call print_string
    
    ; Display time value
    mov si, tmfld
    mov cx, 8
    mov bl, 0Ah        ; Light Green
    mov dh, 3          ; Row 3
    mov dl, 65         ; Column 65 (right after label)
    call print_string


    pop bx
    pop ax
    mov [datetime_return_ptr], bx
    mov [datetime_return_ptr+2], ax
    jmp far [datetime_return_ptr]

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

; Data section
dlabel:    db 'Date:'
tlabel:    db 'Time:'
dtfld:     db '00/00/0000'
tmfld:     db '00:00:00'
press_key: db 'Press any key...'
msg db 'Sai OS, version 1.0 (c) Sep 2025 ...',13,10, '$'
mlen equ $-msg

datetime_return_ptr dw 0,0

times 512-($-$$) db 0  ; Fill the rest of sector with zeros
