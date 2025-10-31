#!/bin/bash
# Build and run OS in DOSBox

# Assemble all modules
nasm -f bin os423V03.asm -o os423V03.bin
nasm -f bin loaderV03.asm -o loaderV03.bin
nasm -f bin datetimeV03.asm -o datetimeV03.bin

# Create empty floppy image (1.44 MB)
dd if=/dev/zero of=a.img bs=512 count=2880

# Write bootloader to sector 0
dd if=os423V03.bin of=a.img bs=512 count=1 conv=notrunc

# Write logo (text file with ASCII art) at sector 50
dd if=logo.txt of=a.img bs=512 count=1 seek=50 conv=notrunc

# Write loader at sector 6
dd if=loaderV03.bin of=a.img bs=512 count=1 seek=5 conv=notrunc

# Write datetime module at sector 7
dd if=datetimeV03.bin of=a.img bs=512 count=1 seek=6 conv=notrunc

# Run in DOSBox
dosbox a.img
