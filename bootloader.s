
; consider switching to nasm for more versatile c-like macros
; or I could just run the C preprocessor on my assembly files
; yeah, that might actually be the play here.

; I need to separate my fasm preprocessor code and my
; assembler code, as well as the metadata code

; bios function references:
; 	succinct list:
; 		https://en.wikipedia.org/wiki/BIOS_interrupt_call
; 	detailed list:
; 		https://grandidierite.github.io/bios-interrupts/


; solution to booting on dell with usb
;	https://forum.osdev.org/viewtopic.php?t=29237


; note, something you can do is format this as a fat16 device


; replace with a struct when ready
macro PartitionEntry {
			rb 16
}



macro offill addr, char {
	if $-$$ > addr
		error "offset overflow"
	else
		repeat addr-($-$$)
			db char
		end repeat
	end if
}

macro offset addr {
	offill addr, 0x0
}

macro abset addr {
	if $ > addr
		error "abset overflow"
	else
		repeat addr-$
			db 0
		end repeat
	end if
}

macro padd start, n
{
	if $-start > n
		error "padd overflow"
	else
		repeat n-($-start)
			db 0
		end repeat
	end if
}

macro assert n, text
{
	if ~(n)
		error
	end if
}



; consider replacing this with a dummy BPB
; Ideally  I want to design my own filesystem and partition system
struc BPB spc, rs, ns, label, filesys {
    ; Dos 4.0 EBPB 1.44MB floppy
    ; http://jdebp.info/FGA/bios-parameter-block.html
    offset 0x0003
    .OEMname:           db    "mkfs.fat"  ; mkfs.fat is what OEMname mkdosfs uses
    offill 0x000B, " "
    ; official start of the sector
    .bytesPerSector:    dw    512
    .sectPerCluster:    db    spc 	; sectors per allocation unit. Ignored if 1
    .reservedSectors:   dw    rs 	; reserved sectors at start for boot
    .numFAT:            db    2		; # of file alloc tables for redundancy. Default is 2
    ; root is located immediately following the FAT, each entry is 32 bytes, can span sectors
    ; value of zero indicates variable size and variable position
    .numRootDirEntries: dw    256	; fixed # of directories in root
    .numSectors:        dw    ns ;2880	; total # of sectors in volume
    .mediaType:         db    0xf0	; obsolete. Make sure it is sane value
    .numFATsectors:     dw    8		; # of sectors allocated for each fat table
    .sectorsPerTrack:   dw    18
    .numHeads:          dw    2
    .numHiddenSectors:  dd    0		; disc-relative block number offset
    .numSectorsHuge:    dd    0
    .driveNum:          db    0
    .reserved:          db    0
    .signature:         db    0x29
    .volumeID:          dd    0x2d7e5a1a
    .volumeLabel:       db    label ; "BitOS BOOT"
    offill 0x0036, " "
    ;padd volumeLabel, 11
    ;assert($-$$=0x0036, "BPB overflow")
    .fileSysType:       db    filesys ; "FAT12"
    offill 0x003E, " "
    ;padd fileSysType, 8
    ;assert($-$$=0x003E, "BPB overflow")
						dq 	  0		; reserved
    offset(0x0046)
}


format binary
use16

org 0x7c00
					; enforce CS:IP to be 0x0000:0x7cxx

start:		cli		; disable interrupts
			jmp  far 0x0000:entryx

		;BPB 1, 1, 2880, "BitOS BOOT", "FAT12"


entryx:		xor  ax, ax
	        mov  ds, ax
	        mov  es, ax
	        mov  ss, ax
	        mov  sp, 7C00h	; I honestly can't tell if this is safe


	        mov ah, 0x06   ; Function 06h - Scroll the window up
	        mov al, 0      ; Clear entire screen
    	    mov bh, 0x07   ; Video attribute (color)
        	mov cx, 0      ; Upper left corner (row = 0, column = 0)
        	mov dx, 0x184F ; Lower right corner (row = 24, column = 79)
        	int 0x10       ; Call BIOS video interrupt


        	mov ah, 02h
        	xor bh, bh
        	xor dx, dx
        	int 0x10	; reset cursor position


			;mov	 ah, 0
			;mov  al, 02h
					; set video mode to 80x25 b/w text mode
			;int  10h

			;mov  ah, 0fh
					; returns dp number in BH
			;int  10h
			;sti		; enable interrupts

;i=0
;rept 7 {
print:		xor  bx, bx	; assume active display page is 0
			mov  cx, teststr
			mov  bx, cx
			push sp
			push bp
printloop:	;mov  ah, 02h
			;mov  dl, byte [cursorx]
			;xor  dh, dh
					; set cursor position
			;int  10h

			;push bx
			;mov  cx, [cursorx]
			;mov  bx, cx
			;mov  al, byte [teststr+bx]
			;mov  cx, 1
			;mov  ah, 0ah
			;pop  bx
					; write character
			;int  10h

			;inc  byte [cursorx]
			;push bx
			;mov  bx, [cursorx]
			;cmp  byte [teststr+bx], 0
			;pop  bx
			;jnz  printloop
			mov  ah, 0eh
			mov  al, [bx]
			test al, al
			jz   endloop
			push bx
			xor  bx, bx
			int  10h
			pop  bx
			inc  bx
			jmp  printloop

endloop:	pop  bp
			pop  sp


;i=i+1
;}

bootlock:	jmp  bootlock




;printstr:	add  sp,
;			push ax
;			push bx
;			push cx
;			mov  cx, ax
;pntstrloop: mov  ah, 0ah
;			mov	 al, [cx]
;			mov  bh,



teststr: 	db 10,10,10,10, "        I live!", 13,10,10,10, "        Fuck you Dell!", 0
					; create a struct for this
;cursorx:	db 0
;cursory:	db 0


;if $-$$ >= 0x01BE
;	error "stage 1 bootloader code overflow"
;end if


;rb (0x01BE-($-0x7c00))

offset 0x01BE

;repeat 0x01BE-($-$$)
;	db 0
;end repeat

;thingy:
;rept (thingy) {
;db 0x00
;}



;PARTTABLE:	rept 4 {PartitionEntry}

offset 0x1BE
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


;times 0x0200 - $ db 0x00
;rb (0x0200-($-0x7c00))


offset 0x01FE

;repeat 0x01FE-($-$$)
;	db 0
;end repeat


					; Boot signature
			db 0x55, 0xAA


;repeat 0x0200-($-$$)
;	db 0
;end repeat

; second segment?
if 1=0
offset 0x0200


org 0x0000

; secondary fake bootloader for now

secondstage:cli		; disable interrupts
			jmp  far 0x0800:bootentry2

		;BPB 1, 1, 2880, "BitOS BOOT", "FAT12"


bootentry2:	xor  ax,ax
	        mov  ds,ax
	        mov  es,ax
	        mov  ss,ax
	        mov  sp,7C00h

			mov	 ah, 0
			mov  al, 02h
					; set video mode to 80x25 b/w text mode
			int  10h

			mov  ah, 0fh
					; returns dp number in BH
			int  10h
			sti		; enable interrupts

;i=0
;rept 7 {
printloop2:	mov  ah, 02h
			mov  dl, byte [cursorx]
			xor  dh, dh
					; set cursor position
			int  10h

			push bx
			mov  cx, [cursorx]
			mov  bx, cx
			mov  al, byte [teststr+bx]
			mov  cx, 1
			mov  ah, 0ah
			pop  bx
					; write character
			int  10h

			inc  byte [cursorx]
			push bx
			mov  bx, [cursorx]
			cmp  byte [teststr+bx], 0
			pop  bx
			jnz  printloop2
;i=i+1
;}

bootlock2:	jmp  bootlock2
end if


; will be faster done outside of the assembly
; extend to make a 1.2M floppy disk
;repeat 0x12C000-($-$$)
;	db 0
;end repeat
