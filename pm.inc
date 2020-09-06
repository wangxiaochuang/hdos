;%1: 段基址
;%2: 段界限
;%3: 属性
%macro Descriptor 3
    dw  %2  &  0FFFFh       ;将段界限的前两个字节写进byte[0,1]
    dw  %1  &  0FFFFh       ;将段基址的前两个字节写进byte[2,3]
    db  (%1 >> 16) & 0FFh   ;将段基址的第三个字节写进byte[4]
    dw  ((%2 >> 8) & 0F00h) | (%3 & 0F0FFh) ;把段界限的高4位（总共20位）写进byte[5]的低4位，同时将属性写进byte[5]剩余的位置和byte[6]
    db  (%1 >> 24) & 0FFh   ;将段基址的第四个字节写进byte[7]
%endmacro

DA_32   EQU 4000h
DA_C    EQU 98h
DA_DRW  EQU 92h
DA_DRWA EQU 93h     
