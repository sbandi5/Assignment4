
	org 0x7c00
	jmp short start
	nop
bsOEM	db "OS423 v.0.2"               ; OEM String

start:
	xor ax, ax
	mov ds, ax

    ; Install VRAM interrupt vectors (int 0x70 -> print, int 0x71 -> clear)
    call install_vram_ivts

;;cls - Clear portion of the screen
	mov bh,7ah		;Attribute (lightgreen on black) 
	mov ch,7		;Upper left row is seven
	mov cl,0		;Upper left column is zero
	mov dh,16		;Lower right row is 24
	mov dl,79		;Lower right column is 79
	push ax
	push es
	xor ax, ax
	mov es, ax
	call far [es:0x0404]
	pop es
	pop ax

;;Create a colored box in the Top
	mov bh,4eh		;Attribute (yellow on red background)
	mov ch,0		;Upper left row is 0
	mov cl,0		;Upper left column is 0
	mov dh,6		;Lower right row is 6
	mov dl,79		;Lower right column is 79
	push ax
	push es
	xor ax, ax
	mov es, ax
	call far [es:0x0404]
	pop es
	pop ax

;;Create a colored box in the bottom
	mov bh,20h		;Attribute (yellow on red background)
	mov ch,17		;Upper left row is 17
	mov cl,0		;Upper left column is 0
	mov dh,24		;Lower right row is 24
	mov dl,79		;Lower right column is 79 
	push ax
	push es
	xor ax, ax
	mov es, ax
	call far [es:0x0404]
	pop es
	pop ax

	

;;;load 2nd sector and run
	mov bx, 0x0002			;es:bx input buffer, temporary set 0x0001:1234
	mov es, bx
	mov bx, 0x3456
	mov ah, 02h				;Function 02h (read sector)
	mov al, 1				;Read one sector
	mov ch, 0				;Cylinder#
	mov cl, 6				;Sector# --> 5 has program
	mov dh, 0				;Head# --> logical sector 1
	mov dl, 0				;Drive# A, 08h=C
	int 13h

	push cs					;Save return segment for after loader completes
	push word return_from_loader	;Save return offset
	jmp word 0x0002:0x3456	;Run program on sector 1, ex:bx

;-------------------------------------------------------------
return_from_loader:
	xor ax, ax
	mov ds, ax
	; Wait for keypress
	xor ah, ah         ; Function 0: wait for keypress
	int 16h            ; BIOS keyboard service

	;;cls - Clear entire screen
	mov bh,0ah		;Attribute (lightgreen on black) 
	mov ch,0		;Upper left row is seven
	mov cl,0		;Upper left column is zero
	mov dh,24		;Lower right row is 24
	mov dl,79		;Lower right column is 79
	push ax
	push es
	xor ax, ax
	mov es, ax
	call far [es:0x0404]
	pop es
	pop ax

	; Print main message using VRAM helper (via far-call wrapper)
	mov si, msg
	mov cx, mlen
	mov bl, 04h
	mov dh, 0
	mov dl, 0
	push ax
	push es
	xor ax, ax
	mov es, ax
	call far [es:0x0400]
	pop es
	pop ax

	; Print trailing characters
	mov si, msg1
	mov cx, mlen1
	mov bl, 04h
	mov dh, 1
	mov dl, 0
	push ax
	push es
	xor ax, ax
	mov es, ax
	call far [es:0x0400]
	pop es
	pop ax

	;hang
    jmp $
    int 20h

;;clear rectangle helper
;;  BH = attribute, CH/CL = upper-left row/col, DH/DL = lower-right row/col (inclusive)
vram_clear_rect:
	push bp
	push di
	push si
	push dx
	push cx
	push bx
	push es

	mov ax, 0xb800
	mov es, ax

	xor ax, ax
	mov al, ch
	mov si, ax
	mov di, ax
	shl si, 6
	shl di, 4
	add si, di
	xor ax, ax
	mov al, cl
	add si, ax
	shl si, 1
	mov di, si

	xor ax, ax
	mov al, dl
	sub al, cl
	inc ax
	mov bp, ax

	xor ax, ax
	mov al, dh
	sub al, ch
	inc ax
	mov si, ax

	mov ax, 80
	sub ax, bp
	shl ax, 1
	mov dx, ax

	mov ah, bh
	mov al, ' '

clear_rect_row:
	mov cx, bp
	rep stosw
	dec si
	jz clear_rect_done
	add di, dx
	jmp clear_rect_row

clear_rect_done:
	pop es
	pop bx
	pop cx
	pop dx
	pop si
	pop di
	pop bp
	ret

;; VRAM print helper (call directly)
;;  DS:SI = text pointer, CX = length, BL = attribute, DH/DL = row/col
vram_print_string:
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

;; (INT handlers removed to save space; use far-call RETF wrappers instead)
; Far-call wrappers for use with CALL FAR [0x0400]
; These preserve registers and return with RETF (so they are safe when invoked with CALL FAR)
vram_print_far_entry:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	call vram_print_string
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	retf

vram_clear_far_entry:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	call vram_clear_rect
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	retf

;; install_vram_ivts: set interrupt vectors for our VRAM services
install_vram_ivts:
	cli
	xor ax, ax
	mov es, ax
	; Write far-call vectors at absolute 0000:0400 for reliable far calls
	; layout: 0x0400: print offset (word), 0x0402: print segment (word)
	;         0x0404: clear offset (word), 0x0406: clear segment (word)
	push cs
	pop ax
	mov word [es:0x0400], vram_print_far_entry
	mov word [es:0x0402], ax
	mov word [es:0x0404], vram_clear_far_entry
	mov word [es:0x0406], ax
	sti
	ret

msg db 'Sai OS, version 1.0 (c) Sep 2025 ...',
mlen equ $-msg

msg1 db 0x0D, '$'
mlen1 equ $-msg1

padding	times 510-($-$$) db 0		;to make MBR 512 bytes
bootSig	db 0x55, 0xaa		;signature (optional)
