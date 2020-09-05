#!/bin/sh

gcc -m32 -fno-asynchronous-unwind-tables -s -c -o tmp/write_vga.o write_vga.c
if [ $? != 0 ]
then
    exit 1
fi
objconv -fnasm tmp/write_vga.o tmp/write_vga.asm

sed -i -r '/^(SECT|extern|global)/d'  tmp/write_vga.asm

nasm -o data/kernel.bin kernel.asm
len=`stat -c "%s" data/kernel.bin`
section=`expr $len / 512`
sed -i "s#{NUM}#${section}#g" boot.asm
nasm -o data/boot.bin boot.asm
./tools/main
