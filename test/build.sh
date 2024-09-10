j30afjli3afjiao

umount /dev/sdb1

nasm -f bin mbr.asm -o mbr.bin
nasm -f bin vbr.asm -o vbr.bin
dd if=mbr.bin of=/dev/sdb
dd if=vbr.bin of=/dev/sdb seek=1


lsblk
