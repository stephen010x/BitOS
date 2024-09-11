
; reference
; https://embeddedartistry.com/blog/2019/04/08/a-general-overview-of-what-happens-before-main/
; https://github.com/mit-pdos/xv6-public

#include "start.h"

format obj

; argc in register %rdi (argument counter)
; argv in register %rsi (argument vector)
; envc in register %rdx (enviroment count)
; envp in register %rcx (enviroment pointer)

; It sounds like enviroment variables are defined by
; my operating system, and aren't strictly neccissary,
; and perhaps not even used by C if not explicitly by 
; the user or more likely the standard libs

; and since this is the kernel, there are no arguments

; I need to make sure the bootloader knows where the 
; entry point is.
; I believe the entry point is 0x00
; We can probably let the C linker handle the org

; my bootloader loads the kernel to 0x1MiB in physical
; memory. However, this will probably be 0x00 in virtual
; memory.
; The stack will start at the top of the segment,
; which is technically the beginning of the segmment too
; only it grows "up"
; So we probably don't need to set up the stack pointer, 
; as it is already in the right spot.

section .text
global _start

_start:
            xor  rbp, rbp
            mov  rdi, 
            
            
            call main