# use objdump to see how the program gets compiled
# use .s files for assembly meant to be linked with C
# use .asm files for standalone assembly

# segment partition of the kernel
KERNPART := 128

## Temporary until filesystem established
TARGET := bitos.raw
BOOTLOD := boot.raw
BINTARG := kernel.bin

CC := gcc
AS := fasm
PP := gcc -E

TMPDIR := tmp
SRCDIR := src
BINDIR := bin

# assembler fasm flags
#AFLAGS :=
# preprocessor flags
PFLAGS :=
# compiler flags
CFLAGS := -masm=intel
# linker flags
LFLAGS :=
# compiler AND linker flags
BFLAGS := -Wall -Wextra -Wpedantic -Wconversion -Wundef

# get goal keyword for object file generation, or make it 'debug'
GOAL := $(firstword $(MAKECMDGOALS))
GOAL := $(if $(GOAL),$(GOAL),fast)
# should grab all paths relative to makefile.
SRCS := $(shell find $(SRCDIR) -name "*.c") $(shell find $(SRCDIR) -name "*.s")
BOOTSRC := $(basename $(BOOTLOD)).asm
OBJS := $(SRCS:%.c=$(TMPDIR)/$(GOAL)/%.c.o) $(SRCS:%.s=$(TMPDIR)/$(GOAL)/%.s.o)
DEPS := $(SRCS:%.c=$(TMPDIR)/$(GOAL)/%.c.d) $(SRCS:%.s=$(TMPDIR)/$(GOAL)/%.s.d)
TARGPATH := $(BINDIR)/$(TARGET)
BOOTPATH := $(TMPDIR)/$(BOOTLOD)
BINTPATH := $(TMPDIR)/$(BINTARG)

ifneq ($(shell uname),Linux)
    $(error This Makefile requires a Linux environment to run)
endif

-include $(DEPS)


all: fast
fast: _fast $(TARGPATH)
debug: _debug $(TARGPATH)
release: _release $(TARGPATH)


_fast: _baremetal
	$(eval PFLAGS += -DDEBUG_MODE)
	$(eval BFLAGS += -g -O0)

_debug: _baremetal
	$(eval PFLAGS += -DDEBUG_MODE)
	$(eval BFLAGS += -g -Og)

_release: _baremetal _optimize

_baremetal:
	$(eval CFLAGS += -ffreestanding)
	$(eval LFLAGS += -nostdlib)

_optimize:
	$(eval LFLAGS += -Wl,--gc-sections -s -flto)
	$(eval BFLAGS += -Os -fno-ident -fno-asynchronous-unwind-tables)
	# look into 'strip' command

#release:
#	fasm bootloader.asm bootloader.raw
#	truncate --size 1228800 bootloader.raw


# temporary until filesystem established
# merge files into target
$(TARGPATH): $(BOOTPATH) $(BINTPATH)
	#truncate -s 1MiB $(TARGPATH)
    mkdir -p $(dir $@)
	touch $@
	dd if=$< of=$@ bs=512 seek=0
	dd if=$< of=$@ bs=512 seek=$(KERNPART)

# link objects to bin
$(BINTPATH): $(OBJS)
	mkdir -p $(dir $@)
	$(CC) $(BFLAGS) $(LFLAGS) -o $@ $^

# assemble bootloader
$(BOOTPATH): $(BOOTSRC)
    mkdir -p $(dir $@)
	$(AS) $< $@



$(TMPDIR)/$(GOAL)/%.c.o: %.c $(TMPDIR)/$(GOAL)/%.c.d
	mkdir -p $(dir $@)
	$(CC) $(BFLAGS) $(CFLAGS) -c $< -o $@

$(TMPDIR)/$(GOAL)/%.s.o: %.s $(TMPDIR)/$(GOAL)/%.s.d
	mkdir -p $(dir $@)
    pres=$(TMPDIR)/$(GOAL)/$(patsubst %.pre.s,%.s,$<)
    $(PP) $< -o $$pres
    $(AS) $$pres $@

$(TMPDIR)/$(GOAL)/%.c.d: %.c
	mkdir -p $(dir $@)
	$(CC) -MM -MT $(patsubst %.d,%.o,$@) -MF $@ -c $<

$(TMPDIR)/$(GOAL)/%.s.d: %.s
	mkdir -p $(dir $@)
	$(CC) -MM -MT $(patsubst %.d,%.o,$@) -MF $@ -c $<


verbose:
    #$(info AFLAGS:=$(AFLAGS))
    $(info PFLAGS:=$(PFLAGS))
    $(info CFLAGS:=$(CFLAGS))
    $(info LFLAGS:=$(LFLAGS))
    $(info BFLAGS:=$(BFLAGS))
    $(info GOALSRCS:=$(GOALSRCS))
    $(info BOOTSRC:=$(BOOTSRC))
    $(info OBJS:=$(OBJS))
    $(info DEPS:=$(DEPS))
    $(info TARGPATH:=$(TARGPATH))
    $(info BOOTPATH:=$(BOOTPATH))
    $(info BINTPATH:=$(BINTPATH))


run:
    bochs

flash:
    # to be added

clean:
	\rm -f $(TMPDIR)
	\rm -f $(BINDIR)

.PHONY: all fast debug release run flash verbose clean
.PHONY: _fast _debug _release _baremetal _optimize
