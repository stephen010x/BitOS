# use objdump to see how the program gets compiled
# use .s files for assembly meant to be linked with C
# use .asm files for standalone assembly

TARGET := bitos.raw
BOOTLOD := boot.raw
BINTARG := kernel.bin

CC := gcc
AS := fasm
PP := gcc -E

TMPDIR := tmp
SRCDIR := src
BINDIR := bin

AFLAGS :=
CFLAGS :=
LFLAGS :=
BFLAGS := -Wall -Wextra -Wpedantic -Wconversion -Wundef

# get goal keyword for object file generation, or make it 'debug'
GOAL := $(firstword $(MAKECMDGOALS))
GOAL := $(if $(GOAL),$(GOAL),fast)
# should grab all paths relative to makefile.
SRCS := $(shell find $(SRCDIR) -name "*.c") $(shell find $(SRCDIR) -name "*.s")
OBJS := $(SRCS:%.c=$(TMPDIR)/$(GOAL)/%.c.o) $(SRCS:%.c=$(TMPDIR)/$(GOAL)/%.s.o)
DEPS := $(SRCS:%.c=$(TMPDIR)/$(GOAL)/%.d)
TARGPATH := $(BINDIR)/$(TARGET)
BOOTPATH := $(TMPDIR)/$(BOOTLOD)
BINTPATH := $(TMPDIR)/$(BINTARG)

-include $(DEPS)


all: fast
fast: _fast $(TARGPATH)
debug: _debug $(TARGPATH)
release: _release $(TARGPATH)


_fast: _baremetal
	$(eval CFLAGS += -DDEBUG_MODE)
	$(eval BFLAGS += -g -O0)

_debug: _baremetal
	$(eval CFLAGS += -DDEBUG_MODE)
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



$(TARGPATH): $(BINTARG) $(BOOTLOD)
	# merge them here

$(BINTPATH): $(OBJS)
	#$(info DEPS is $(DEPS))
	-@mkdir $(BINDIR) 2>NUL
	$(CC) $(BFLAGS) $(LFLAGS) -o $@ $^

$(BOOTPATH): $(BOOTLOD)



$(TMPDIR)/$(GOAL)/%.o: %.c $(TMPDIR)/$(GOAL)/%.d
	-@cmd /E:ON /C mkdir $(subst /,\,$(dir $@))
	$(CC) $(BFLAGS) $(CFLAGS) -c $< -o $@

$(TMPDIR)/$(GOAL)/%.d: %.c
	-@cmd /E:ON /C mkdir $(subst /,\,$(dir $@))
	$(CC) -MM -MT $(patsubst %.d,%.o,$@) -MF $@ -c $<

$(TMPDIR)/$(GOAL)/%.d: %.s

$(TMPDIR)/$(GOAL)/%.d: %.asm


run:

flash:


clean:
	\rm -f $(TMPDIR)
	\rm -f $(BINDIR)

.PHONY: all fast debug release run flash clean
.PHONY: _fast _debug _release _baremetal _optimize
