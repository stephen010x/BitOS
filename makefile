
# objcopy -O binary infile outfile
# Will dump the raw binary from a fully linked infile to outfile discarding all headers,
# symbol tables etc.
# verify with objdump


all:
	fasm bootloader.s bootloader.raw
	truncate --size 1228800 bootloader.raw
