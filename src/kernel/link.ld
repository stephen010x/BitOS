SECTIONS{
	. = 0x80000000;

	.text : AT(0x0000) {
		*(.start)
		*(.text)
	}
	.data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
	_end = .;
}
