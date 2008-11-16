#
#   OPTIONS
#
DEBUG := 1
#DEBUG_PARANOID := 1


# OS
OS := LINUX
#OS := WIN32
#OS := MACOS
export OS


# Data path
#DATA_DEF := "ndata"


#
#   VERSION
#
VMAJOR      := 0
VMINOR      := 3
VREV        := 3
VERSION     := -DVMAJOR=$(VMAJOR) -DVMINOR=$(VMINOR) -DVREV=$(VREV)
VERSIONFILE := VERSION


#
#   OBJS
#
APPNAME := naev
OBJS    := $(patsubst %.c,%.o,$(wildcard src/*.c))


#
#   CFLAGS
#
CLUA   := -Ilib/lua
CSDL   := $(shell sdl-config --cflags)
CXML   := $(shell xml2-config --cflags)
CTTF   := $(shell freetype-config --cflags)
CPNG   := $(shell libpng-config --cflags)
CGL    :=
CFLAGS := $(CLUA) $(CSDL) $(CXML) $(CTTF) $(CPNG) $(CGL) $(VERSION) -D$(OS)


#
#   LDFLAGS
#
LDLUA   := lib/lua/liblua.a
LDSDL   := $(shell sdl-config --libs) -lSDL_image -lSDL_mixer
LDXML   := $(shell xml2-config --libs)
LDTTF   := $(shell freetype-config --libs)
LDPNG   := $(shell libpng-config --libs)
LDGL    := -lGL
LDFLAGS := -lm $(LDLUA) $(LDSDL) $(LDXML) $(LDTTF) $(LDPNG) $(LDGL)


# OS Stuff

ifeq ($(OS),LINUX)
CFLAGS += -D_POSIX_SOURCE
endif

# Debug stuff

ifdef DEBUG
CFLAGS += -W -Wall -Wextra -Wunused -Wshadow -Wpointer-arith -Wmissing-prototypes -Winline -Wcast-align -Wmissing-declarations -fstack-protector -fstack-protector-all -g -DDEBUG -DLUA_USE_APICHECK -std=c99 -ansi

ifdef DEBUG_PARANOID
CFLAGS += -DDEBUG_PARANOID
endif # DEBUG_PARANOID

# Handle OS Debug stuff here.

ifeq ($(OS),LINUX)
LDFLAGS += -rdynamic
endif # LINUX

else # DEBUG
CFLAGS += -O2 -funroll-loops -pipe -std=c99 -ansi
endif # DEBUG


#
#   DATA
#
DATA_AI   := 	$(wildcard ai/*.lua \
					ai/include/*.lua \
					ai/tpl/*.lua )
DATA_GFX  := 	$(wildcard gfx/*.png \
					gfx/loading/*.png \
					gfx/gui/*.png \
					gfx/logo/*.png \
					gfx/outfit/space/*.png \
					gfx/outfit/store/*.png \
					gfx/planet/exterior/*.png \
					gfx/planet/space/*.png \
					gfx/ship/*.png \
					gfx/spfx/*.png)
DATA_XML  := 	$(wildcard dat/*.xml dat/*.ttf dat/intro)
DATA_SND  := 	$(wildcard snd/music/*.ogg snd/sounds/*.wav) snd/music.lua
DATA_MISN := 	$(wildcard dat/missions/*.lua)
DATA      := 	ndata
DATAFILES := 	$(DATA_AI) $(DATA_GFX) $(DATA_XML) $(DATA_SND) $(DATA_MISN)


#
#   TARGETS
#
.PHONY: all help lua utils docs clean distclean


%.o:	%.c %.h
	@$(CC) -c $(CFLAGS) -o $@ $<
	@echo "   CC   $@"


all:	utils ndata lua naev


help:
	@echo "Possible targets are:":
	@echo "       lua - builds Lua support"
	@echo "      naev - builds the naev binary"
	@echo "     mkpsr - builds the mkspr utilitily"
	@echo "     ndata - creates the ndata file"
	@echo "     utils - builds all the utilities"
	@echo "      docs - creates the doxygen documentation"
	@echo "     clean - removes naev's main binary and ndata file"
	@echo " distclean - removes everything done"


$(APPNAME): $(OBJS)
	@$(CC) $(LDFLAGS) -o $(APPNAME) $(OBJS) lib/lua/liblua.a
	@echo "   LD   $(APPNAME)"


lua: lib/lua/liblua.a


lib/lua/liblua.a:
	+@$(MAKE) -C lib/lua a


pack: src/md5.c src/pack.c utils/pack/main.c
	+@$(MAKE) -C utils/pack


mkspr: utils/mkspr/main.c
	+@$(MAKE) -C utils/mkspr


$(VERSIONFILE):
	@echo -n "$(VMAJOR).$(VMINOR).$(VREV)" > $(VERSIONFILE)


ndata: pack $(DATAFILES)
	@echo -n "$(VMAJOR).$(VMINOR).$(VREV)" > $(VERSIONFILE)
	@echo "   DAT  ndata"
	@./pack $(DATA) $(DATAFILES) $(VERSIONFILE)


utils: pack mkspr


docs:
	@( cd src; doxygen )


clean:
	@echo "   Removing ndata"
	@$(RM) $(DATA)
	@echo "   Removing object files"
	@$(RM) $(OBJS)
	@echo "   Removing main binary ($(APPNAME))"
	@$(RM) $(APPNAME)


distclean: clean
	@echo "   Cleaning utilities"
	@$(MAKE) -C utils/pack clean
	@$(MAKE) -C utils/mkspr clean
	@echo "   Cleaning Lua"
	@$(MAKE) -C lib/lua clean
	@echo "   Removing build tool binaries"
	@$(RM) mkspr pack


