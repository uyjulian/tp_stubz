#############################################
##                                         ##
##    Copyright (C) 2020-2020 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
## See details of license at "license.txt" ##
##                                         ##
#############################################

TP_STUB_BASE ?= external/tp_stubz/
TOOL_TRIPLET_PREFIX ?= i686-w64-mingw32-
CC := $(TOOL_TRIPLET_PREFIX)gcc
CXX := $(TOOL_TRIPLET_PREFIX)g++
ASM := /Users/julian/Downloads/nasm-2.14.03rc2/nasm
WINDRES := $(TOOL_TRIPLET_PREFIX)windres
STRIP := $(TOOL_TRIPLET_PREFIX)strip
7Z := 7z
export GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I$(TP_STUB_BASE) -I.
ALLSRCFLAGS += $(INCFLAGS)
ASMFLAGS += $(ALLSRCFLAGS) -fwin32 -DWIN32
OPTFLAGS := -march=pentium4 -mfpmath=sse -Ofast
CFLAGS += -gstabs
CFLAGS += -fPIC
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DMINGW_HAS_SECURE_API -DUNICODE -D_UNICODE -DNO_STRICT
CXXFLAGS += $(CFLAGS) -fpermissive
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += -static -static-libstdc++ -static-libgcc -Wl,--kill-at -fPIC
LDFLAGS_LIB += -shared
LDLIBS += 

%.o: %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) $(OPTFLAGS) -o $@ $<

%.o: %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) $(OPTFLAGS) -o $@ $<

%.o: %.nas
	@printf '\t%s %s\n' ASM $<
	$(ASM) $(ASMFLAGS) $< -o$@ 

%.o: %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

PROJECT_BASENAME ?= unknown
BINARY ?= $(PROJECT_BASENAME)_unstripped.dll
BINARY_STRIPPED ?= $(PROJECT_BASENAME).dll
ARCHIVE ?= $(PROJECT_BASENAME).$(GIT_TAG).7z

export RC_URL ?= https://github.com/uyjulian/$(PROJECT_BASENAME)
export RC_COMMENTS ?= Source code for the latest version of this product is located on the World Wide Web at $(RC_URL)
export RC_DESC ?= $(PROJECT_BASENAME) Plugin for TVP(KIRIKIRI) (2/Z)
export RC_INTERNALNAME ?= $(PROJECT_BASENAME)
export RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2020 Julian Uy; See details of license at license.txt, or the source code location.
export RC_ORIGINALFILENAME ?= $(BINARY_STRIPPED)
export RC_PRODUCTNAME ?= $(PROJECT_BASENAME) Plugin for TVP(KIRIKIRI) (2/Z)

WINDRESFLAGS +=  

SOURCES += $(TP_STUB_BASE)/tp_stub.cpp $(TP_STUB_BASE)/common.rc
OBJECTS := $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)
OBJECTS := $(OBJECTS:.nas=.o)
OBJECTS := $(OBJECTS:.rc=.o)

all: $(BINARY_STRIPPED)

archive: $(ARCHIVE)

clean:
	rm -f $(OBJECTS) $(OBJECTS_BIN) $(BINARY) $(BINARY_STRIPPED) $(ARCHIVE) $(TP_STUB_BASE)/common_ppdefs.rc

$(TP_STUB_BASE)/common.rc: $(TP_STUB_BASE)/common_ppdefs.rc

$(TP_STUB_BASE)/common_ppdefs.rc:
	@printf '#define RC_URL \"%s\"\n#define RC_COMMENTS \"%s\"\n#define RC_DESC \"%s\"\n#define RC_INTERNALNAME \"%s\"\n#define RC_LEGALCOPYRIGHT \"%s\"\n#define RC_ORIGINALFILENAME \"%s\"\n#define RC_PRODUCTNAME \"%s\"\n#define GIT_TAG \"%s\"\n'  "$${RC_URL}" "$${RC_COMMENTS}" "$${RC_DESC}" "$${RC_INTERNALNAME}" "$${RC_LEGALCOPYRIGHT}" "$${RC_ORIGINALFILENAME}" "$${RC_PRODUCTNAME}" "$${GIT_TAG}" > $@

$(ARCHIVE): $(BINARY_STRIPPED) LICENSE
	@printf '\t%s %s\n' 7Z $@
	rm -f $(ARCHIVE)
	$(7Z) a $@ $^

$(BINARY_STRIPPED): $(BINARY)
	@printf '\t%s %s\n' STRIP $@
	$(STRIP) -o $@ $^

$(BINARY): $(OBJECTS)
	@printf '\t%s %s\n' LNK $@
	$(CXX) $(CFLAGS) $(LDFLAGS) $(LDFLAGS_LIB) -o $@ $^ $(LDLIBS)
