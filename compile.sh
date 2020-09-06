#!/bin/sh

rm tmp/write_vga.o data/kernel.bin data/system.img 2> /dev/null

gcc -m32 -fno-asynchronous-unwind-tables -s -c -o tmp/write_vga.o write_vga.c
test $? != 0 && exit 1

objconv -fnasm tmp/write_vga.o tmp/write_vga.asm

sed -i -r '/^(SECT|extern|global)/d'  tmp/write_vga.asm

nasm -o data/kernel.bin kernel.asm
test $? != 0 && exit 1

len=`stat -c "%s" data/kernel.bin`
section=`expr $len / 512`
sed -i "20c mov AL, ${section}" boot.asm
nasm -o data/boot.bin boot.asm
./tools/main
