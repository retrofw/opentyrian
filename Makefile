# BUILD SETTINGS ###########################################

CHAINPREFIX := /opt/mipsel-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC  := $(CROSS_COMPILE)gcc
LD  := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
STRIP := $(CROSS_COMPILE)strip
RC  := $(CROSS_COMPILE)windres

SYSROOT := $(shell $(CC) --print-sysroot)
SDL_CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

PLATFORM := DINGUX

TARGET := opentyrian/opentyrian.dge

WITH_NETWORK := false

############################################################

SRCS := $(wildcard src/*.c)
OBJS := $(SRCS:src/%.c=/tmp/opentyrian/%.o)
RELEASE := 1

# FLAGS ####################################################

ifneq (1, $(RELEASE))
    EXTRA_CFLAGS += -g3 -O0 -Werror
else
    EXTRA_CFLAGS += -g0 -O2 -DNDEBUG
endif

EXTRA_CFLAGS += -MMD -pedantic -Wall -Wextra -Wno-missing-field-initializers

ifeq ($(WITH_NETWORK), true)
    EXTRA_CFLAGS += -DWITH_NETWORK
endif

#HG_REV := $(shell hg id -ib && touch src/hg_revision.h)
#ifneq ($(HG_REV), )
#    EXTRA_CFLAGS += '-DHG_REV="$(HG_REV)"'
#endif

EXTRA_CFLAGS += -DHG_REV="\"r$(shell git rev-list --reverse HEAD | wc -l)\""

EXTRA_LDLIBS += -lm

ifeq ($(WITH_NETWORK), true)
    SDL_LIBS += -lSDL_net
endif
ALL_CFLAGS += -std=c99  -I./src -DTARGET_$(PLATFORM) $(EXTRA_CFLAGS) $(SDL_CFLAGS) $(CFLAGS) -DRGGAME
ALL_LDFLAGS += $(LDFLAGS)
LDLIBS += $(EXTRA_LDLIBS) $(SDL_LIBS)

# RULES ####################################################

.PHONY : all release clean

clean :
	rm -rf /tmp/opentyrian/*
	rm -f $(TARGET)

ifneq ($(MAKECMDGOALS), clean)
	-include $(OBJS:.o=.d)
endif

all: $(OBJS)
	$(CC) -o $(TARGET) $(ALL_LDFLAGS) $^ $(LDLIBS)
ifeq (1, $(RELEASE))
	$(STRIP) $(TARGET)
endif

/tmp/opentyrian/%.o : src/%.c
	@mkdir -p "$(dir $@)"
	$(CC) -c -o $@ $(ALL_CFLAGS) $<

ipk: all
	@rm -rf /tmp/.opentyrian-ipk/ && mkdir -p /tmp/.opentyrian-ipk/root/home/retrofw/games/opentyrian /tmp/.opentyrian-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r opentyrian/data opentyrian/opentyrian.conf opentyrian/opentyrian.elf opentyrian/opentyrian.man.txt opentyrian/opentyrian.png /tmp/.opentyrian-ipk/root/home/retrofw/games/opentyrian
	@cp opentyrian/opentyrian.lnk /tmp/.opentyrian-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" opentyrian/control > /tmp/.opentyrian-ipk/control
	@cp opentyrian/conffiles /tmp/.opentyrian-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.opentyrian-ipk/control.tar.gz -C /tmp/.opentyrian-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.opentyrian-ipk/data.tar.gz -C /tmp/.opentyrian-ipk/root/ .
	@echo 2.0 > /tmp/.opentyrian-ipk/debian-binary
	@ar r opentyrian/opentyrian.ipk /tmp/.opentyrian-ipk/control.tar.gz /tmp/.opentyrian-ipk/data.tar.gz /tmp/.opentyrian-ipk/debian-binary

opk: all
	@mksquashfs \
	opentyrian/default.retrofw.desktop \
	opentyrian/data \
	opentyrian/opentyrian.conf \
	opentyrian/opentyrian.dge \
	opentyrian/opentyrian.man.txt \
	opentyrian/opentyrian.png \
	opentyrian/opentyrian.opk \
	-all-root -noappend -no-exports -no-xattrs
