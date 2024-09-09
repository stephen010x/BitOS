

; I need to separate my fasm preprocessor code and my
; assembler code, as well as the metadata code

; bios function references:
; 	succinct list:
; 		https://en.wikipedia.org/wiki/BIOS_interrupt_call
; 	detailed list:
; 		https://grandidierite.github.io/bios-interrupts/


; solution to booting on dell with usb
;	https://forum.osdev.org/viewtopic.php?t=29237


; replace with a struct when ready
macro PartitionEntry {
			rb 16
}


macro offset addr {
	if $-$$ > addr
		error "offset overflow"
	else
		repeat addr-($-$$)
			db 0
		end repeat
	end if
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

macro padd start, n {
	if $-start > n
		error "padd overflow"
	else
		repeat n-($-start)
			db 0
		end repeat
	end if
}

struct BPB


format binary
use16

org 0x7c00
					; enforce CS:IP to be 0x0000:0x7cxx

mbrstart:	jmp  far 0x0000:bootentry	; jmp far might not exist on classic 8086

	; issues with booting on real hardware occur without BPB
	; replace this with a struct
	offset 0x0003
    ; Dos 4.0 EBPB 1.44MB floppy
    OEMname:           db    "mkfs.fat"  ; mkfs.fat is what OEMname mkdosfs uses
    bytesPerSector:    dw    512
    sectPerCluster:    db    1
    reservedSectors:   dw    1
    numFAT:            db    2
    numRootDirEntries: dw    224
    numSectors:        dw    2880
    mediaType:         db    0xf0
    numFATsectors:     dw    9
    sectorsPerTrack:   dw    18
    numHeads:          dw    2
    numHiddenSectors:  dd    0
    numSectorsHuge:    dd    0
    driveNum:          db    0
    reserved:          db    0
    signature:         db    0x29
    volumeID:          dd    0x2d7e5a1a
    volumeLabel:       db    "NO NAME"
    padd volumeLabel, 11
    fileSysType:       db    "FAT12"
    padd fileSysType, 8

bootentry:	xor  ax,ax
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

;i=0
;rept 7 {
printloop:	cli
			mov  ah, 02h
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
			jnz  printloop
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



teststr: 	db "I live!", 0
					; create a struct for this
cursorx:	db 0
cursory:	db 0


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



PARTTABLE:	rept 4 {PartitionEntry}


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
offset 0x0200


org 0x8000

secondstage: db "bigboot here"




; will be faster done outside of the assembly
; extend to make a 1.2M floppy disk
;repeat 0x12C000-($-$$)
;	db 0
;end repeat
