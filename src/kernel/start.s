
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
; I believe the entry point is 0x00 (nope, it isn't)
; We can probably let the C linker handle the org

; my bootloader loads the kernel to 0x1MiB in physical
; memory. However, this will probably be 0x00 in virtual
; memory.
; The stack will start at the top of the segment,
; which is technically the beginning of the segment too
; only it grows "up"
; So we probably don't need to set up the stack pointer,
; as it is already in the right spot.

; According to this site:
; https://www.hackerearth.com/practice/notes/memory-layout-of-c-program/
; The text and intitilized data are stored in the file, and the
; uninitilized data is zeroed out at runtime.

; also, the void pointer means that our text segment doesn't actually start
; at zero. We might also need room for some kernal processes and whatnot.
; So for now it might actually start at 0x80000000
; I assume that it is the job of start to initilize the .bss segment. It
; doesn't make sense for the bootloader/kernel to do that.
; for that though we need a header.

; hah I just realized that enviroment variables are literally just the
; variable set by the shell like $PATH

; Also, it turns out that as long as I don't redefine the _start function like
; I am doing with my kernel, then C programs will zero out the .bss segment themselves
; Therefore, I don't need to do it outright. But eventually I wnat to implement my
; .RUN executable format.

section .text
global _start
org 0x80000000

_start:
            xor  rbp, rbp
            mov  rdi,


            call main
