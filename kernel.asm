%include "pm.inc"

org 0x9000

jmp LABEL_BEGIN

[SECTION .gdt]
;                                 段基址  段界限           属性
LABEL_GDT:          Descriptor      0,       0,               0
LABEL_DESC_CODE32:  Descriptor      0,   SegCode32Len - 1,    DA_C + DA_32
LABEL_DESC_VIDEO:   Descriptor   0B8000h,   0ffffh,           DA_DRW
LABEL_DESC_VRAM:    Descriptor      0,   0ffffffffh,          DA_DRW
LABEL_DESC_STACK:   Descriptor      0,   TopOfStack,          DA_DRW+DA_32


  
GdtLen  equ     $ - LABEL_GDT   
GdtPtr  dw      GdtLen - 1      
        dd      0

SelectorCode32  equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo   equ LABEL_DESC_VIDEO - LABEL_GDT
SelectorStack   equ LABEL_DESC_STACK - LABEL_GDT
SelectorVram    equ LABEL_DESC_VRAM - LABEL_GDT

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h

    mov al, 0x13
    mov ah, 0
    int 0x10            ; 开启显卡的图像模式

    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, LABEL_SEG_CODE32       ;到这里，eax存储了实模式下LABEL_SEG_CODE32代码段的地址

    ;现在ax表示了地址的低16位
    mov word [LABEL_DESC_CODE32 + 2], ax
    shr eax, 16                     ;将地址的高16位放到ax中
    mov byte [LABEL_DESC_CODE32 + 4], al
    mov byte [LABEL_DESC_CODE32 + 7], ah    
    ;到这里为止我们就将地址的基地址放到了描述符的2347位置，总共是4个字节32位

    ;set stack for c language
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, LABEL_STACK
    mov word [LABEL_DESC_STACK + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_STACK + 4], al
    mov byte [LABEL_DESC_STACK + 7], ah

    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_GDT
    mov dword [GdtPtr + 2], eax
    ;这几行代码是为了将我们定义的数据描述符表的起始地址放到GdtPtr
    lgdt [GdtPtr]       ;BIOS调用，作用是将GdtPtr加载到CPU

    cli         ;关中断，防止被打扰
    in al, 92h
    or al, 00000010b
    out 92h, al

    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; 这几行代码就开启了保护模式

    jmp dword SelectorCode32: 0


[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
    ; init stack for c code
    mov ax, SelectorStack
    mov ss, ax                  ;ss指向堆栈描述符的
    mov esp, TopOfStack         ;栈顶在高地址处

    mov ax, SelectorVram
    mov ds, ax

C_CODE_ENTRY:
    %include "tmp/write_vga.asm"        ; 引入c语言编写的逻辑

io_hlt:                         ;void io_hlt(void)
    HLT
    RET

io_in8:
    mov edx, [esp + 4]
    mov eax, 0
    in  al, dx
io_in16:
    mov edx, [esp + 4]
    mov eax, 0
    in  ax, dx
io_in32:
    mov edx, [esp + 4]
    in  eax, dx
    ret
io_out8:
    mov edx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret
io_out16:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    out dx, ax
    ret
io_out32:
    mov edx, [esp + 4]
    mov eax, [esp + 8]
    out dx, eax
    ret
io_cli:             ;关闭中断
    CLI             ;设置eflags寄存器的第九位为0
    RET
io_load_eflags:     ;eflags是一个16位的寄存器，每一位的打开和关闭都对应不同的功能
    pushfd
    pop eax
    ret
io_store_eflags:
    mov eax, [esp + 4]
    push eax
    popfd
    ret

SegCode32Len    equ $ - LABEL_SEG_CODE32

[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
    times 512 db 0
TopOfStack equ $ - LABEL_STACK
