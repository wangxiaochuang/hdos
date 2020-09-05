org 0x7c00;

LOAD_ADDR EQU 0x9000

entry:
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov si, ax

readFloppy:
    mov CH, 1       ;CH 存储柱面号
    mov DH, 0       ;DH 存储磁头号
    mov CL, 2       ;CL 存储扇区号
    
    mov BX, LOAD_ADDR   ;ES:BX 从软盘读到的数据存储到内存的地址；ES*16+BX就是真实的地址
    
    mov AH, 0x02    ;AH=02 表示读盘操作
    mov AL, 4   ;AL 表示要连续读取的扇区
    mov DL, 0       ;驱动器编号，如果只有一个软盘驱动器就写死为0
    INT 0x13        ;调用BIOS中断实现读盘操作
    JC fin          ;读盘操作失败后的指令
    jmp LOAD_ADDR   ;转移控制权

fin:
    HLT
    jmp fin
