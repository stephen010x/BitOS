;*********************************************
;	mbr.asm
;
;*********************************************

bits 16								; we are in 16 bit real mode

org	0								; we will set regisers later

;*********************************************
;	Entry Point
;*********************************************

main:

	;----------------------------------------------------
	; code located at 0000:7C00, adjust segment registers
	;----------------------------------------------------

			cli						; disable interrupts
			mov ax, 0x07C0			; setup registers to point to our segment
			mov ds, ax
			mov es, ax				; es: segment to put loaded data into (bx: offset)
			mov fs, ax	; wait, aren't fs and gs 32 bit?
			mov gs, ax

	;----------------------------------------------------
	; create stack
	;----------------------------------------------------

			mov ax, 0x0000			; set the stack
			mov ss, ax
			mov sp, 0xFFFF
			sti						; restore interrupts

	;----------------------------------------------------
	; save drive-idx we booted from
	;----------------------------------------------------

			mov [drive_idx], dl

	;----------------------------------------------------
	; Display loading message
	;----------------------------------------------------

			mov si, msgTxt
			call Print

	;----------------------------------------------------
	; Get Drive Parameters from BIOS
	;----------------------------------------------------

;			call GetDriveParams

	;----------------------------------------------------
	; Load Volume Boot Record (VBR) from sector 1 (2nd sector), to 0x0050:0000 (i.e. 0x500)
	;----------------------------------------------------
			mov eax, 1			; read (from) 2nd sector
			mov cx, 1			; read 1 sector
			mov bx, 0x0050		; to 0x0050:0000
			mov di, 0
			call ReadSectors

			mov dl, [drive_idx]

			; jump to 0x500
			push WORD 0x0050
			push WORD 0x0000
			retf


;************************************************
; Prints a string
; IN:
;		DS:SI (0 terminated string)
;************************************************
Print:		lodsb				; load next byte from string from SI to AL
			or	al, al			; Does AL=0?
			jz .Back			; Yep, null terminator found-bail out
			mov	ah, 0x0E		; Nope-Print the character
			int	0x10
			jmp	Print			; Repeat until null terminator found
.Back		ret					; we are done, so return


;GetDriveParams:	; (DS:SI ptr to buffer)
;			mov ah, 0x48
;			mov dl, [drive_idx]
;			push ds
;			mov bx, 0x50
;			mov ds, bx
;			mov si, 0
;			int 0x13
;			; save result
;			mov ax, 0x50
;			mov ds, ax
;			mov si, 0
;			mov eax, [ds:si+4]
;			mov [phys_cylinders], eax
;			mov eax, [ds:si+8]
;			mov [phys_heads], eax
;			mov eax, [ds:si+12]
;			mov [phys_sectors], eax
;			mov ax, [ds:si+24]
;			mov [bytes_per_sector], ax
;			pop ds
;			ret


;************************************************
; Reads a series of sectors
; IN: 	EAX (Starting sector)
;		CX (Number of sectors to read)
;		BX:DI (Buffer to read to)
;************************************************
ReadSectors:
			pusha
			mov bp, 0x0005				; max. 5 retries
.Again		mov dl, [drive_idx]
			mov BYTE [buff], 0x10		; size of this structure (1 byte)
			mov BYTE [buff+1], 0		; always zero (1 byte)
			mov WORD [buff+2], cx		; number of sectors to read (2 bytes)
			mov WORD [buff+4], di		; segment:offset ptr to memory to read to (4 bytes)
			mov WORD [buff+6], bx
			mov DWORD [buff+8], eax		; read from sector (8 bytes)
			mov DWORD [buff+12], 0
			mov ah, 0x42
			mov si, buff
			int 0x13
			jnc	.Ok
			dec bp
			jnz	.Again
			mov si, msgErrTxt
			call Print
		jmp $
			int 0x18
.Ok			popa
			ret


buff				times 16 db 0		; Note: DAP-buff is not 16-byte aligned. Problem!?

msgTxt				db 0x0D, 0x0A, "*** USB (MBR) ***", 0x0D, 0x0A, 0x00
msgErrTxt			db "VBR error", 0x0D, 0x0A, 0x00
drive_idx			db 0
;phys_cylinders		dd 0
;phys_heads			dd 0
;phys_sectors		dd 0
;bytes_per_sector	dw 0



; Partition1 0x01BE  (i.e. first partition-entry begins from 0x01BE)
; Partition2 0x01CE
; Partition3 0x01DE
; Partition4 0x01EE
; We only fill/use Partition1
TIMES 0x1BE-($-$$) DB 0
db 0x80			; Boot indicator flag (0x80 means bootable)
db 0			; Starting head
db 3		; Starting sector (6 bits, bits 6-7 are upper 2 bits of cylinder)
db 0			; Starting cylinder (10 bits)
db 0x8B			; System ID	(0x8B means FAT32)
db 0			; Ending head
db 100			; Ending sector (6 bits, bits 6-7 are upper 2 bits of cylinder)
db 0			; Ending cylinder (10 bits)
dd 2		; Relative sector (32 bits, start of partition)
dd 97	; Total sectors in partition (32 bits)
; it's a dummy partition-entry (sectornumbers can't be zeros,
; starting CHS and LBA values should be the same if converted to each other).

TIMES 510-($-$$) DB 0
DW 0xAA55
