;*********************************************
;	vbr.asm
;
;*********************************************

bits 16								; we are in 16 bit real mode

org	0								; we will set regisers later

;start:	jmp	main					; jump to start of bootloader

;*********************************************
;	BIOS Parameter Block
;*********************************************

; BPB Begins 3 bytes from start. We do a far jump, which is 3 bytes in size.
; If you use a short jump, add a "nop" after it to offset the 3rd byte.

;bpbOEM					db "My OS   "		; OEM identifier (Cannot exceed 8 bytes!)
;bpbBytesPerSector:  	DW 512
;bpbSectorsPerCluster:	DB 1				; we want 1 sector/cluster
;bpbReservedSectors: 	DW 1				; the Bootsector (it won't have a FAT)
;bpbNumberOfFATs:		DB 2				; FAT12 has 2 FATs
;bpbRootEntries:		DW 224				; Floppy has max. 224 dirs in its root dir
;bpbTotalSectors:		DW 2880
;bpbMedia:				DB 0xF0				; 0xf8  ;; 0xF1	; Info about the disk; it's a bit pattern
;bpbSectorsPerFAT:		DW 9
;bpbSectorsPerTrack:	DW 18
;bpbHeadsPerCylinder:	DW 2
;bpbHiddenSectors:		DD 0
;bpbTotalSectorsBig:	DD 0
;bsDriveNumber:			DB 0 				; not 1 !?
;bsUnused:				DB 0
;bsExtBootSignature:	DB 0x29
;bsSerialNumber:		DD 0xa0a1a2a3
;bsVolumeLabel:			DB "MOS FLOPPY "	; exactly 11 bytes
;bsFileSystem:			DB "FAT12   "		; exactly 8 bytes



;*********************************************
;	Bootloader Entry Point
;*********************************************

main:

	;----------------------------------------------------
	; code located at 0000:0500, adjust segment registers
	;----------------------------------------------------

			cli						; disable interrupts
			mov ax, 0x0050			; setup registers to point to our segment
			mov ds, ax
			mov es, ax
			mov fs, ax
			mov gs, ax

	;----------------------------------------------------
	; create stack
	;----------------------------------------------------

			mov ax, 0x0000			; set the stack
			mov ss, ax
			mov sp, 0xFFFF
			sti						; restore interrupts

	;----------------------------------------------------
	; Ensure 80*25
	;----------------------------------------------------

;			mov ax, 3				; mode 80*25, clearscreen
;			int 10h

	;----------------------------------------------------
	; Display loading message
	;----------------------------------------------------

			mov si, msgTxt
			call Print

			hlt


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


msgTxt				db 0x0D, 0x0A, "*** Volume Boot Record ***", 0x0D, 0x0A, 0x00



TIMES 510-($-$$) DB 0
DW 0xAA55

