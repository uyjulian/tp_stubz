#############################################
##                                         ##
##    Copyright (C) 2020-2021 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
## See details of license at "license.txt" ##
##                                         ##
#############################################

EXTRA_DIST ?= LICENSE

TP_STUB_BASE ?= external/tp_stubz/
TARGET_ARCH ?= intel32
USE_STABS_DEBUG ?= 0
USE_POSITION_INDEPENDENT_CODE ?= 0
USE_TVPSND ?= 0
USE_ARCHIVE_HAS_GIT_TAG ?= 0
ifeq (x$(TARGET_ARCH),xarm32)
TOOL_TRIPLET_PREFIX ?= armv7-w64-mingw32-
endif
ifeq (x$(TARGET_ARCH),xarm64)
TOOL_TRIPLET_PREFIX ?= aarch64-w64-mingw32-
endif
ifeq (x$(TARGET_ARCH),xintel64)
TOOL_TRIPLET_PREFIX ?= x86_64-w64-mingw32-
endif
TOOL_TRIPLET_PREFIX ?= i686-w64-mingw32-
CC := $(TOOL_TRIPLET_PREFIX)gcc
CXX := $(TOOL_TRIPLET_PREFIX)g++
AR := $(TOOL_TRIPLET_PREFIX)ar
LD := $(TOOL_TRIPLET_PREFIX)ld
ASM := nasm
YACC := yacc
WINDRES := $(TOOL_TRIPLET_PREFIX)windres
STRIP := $(TOOL_TRIPLET_PREFIX)strip
7Z := 7z
ifeq (x$(TARGET_ARCH),xintel32)
OBJECT_EXTENSION ?= .o
endif
OBJECT_EXTENSION ?= .$(TARGET_ARCH).o
DEP_EXTENSION ?= .dep.make
export GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I$(TP_STUB_BASE) -I.
ALLSRCFLAGS += $(INCFLAGS)
ASMFLAGS += $(ALLSRCFLAGS) -fwin32 -DWIN32
OPTFLAGS := -O3
ifeq (x$(TARGET_ARCH),xintel32)
OPTFLAGS += -march=pentium4 -mfpmath=sse
endif
ifeq (x$(TARGET_ARCH),xintel32)
ifneq (x$(USE_STABS_DEBUG),x0)
CFLAGS += -gstabs
else
CFLAGS += -gdwarf-2
endif
else
CFLAGS += -gdwarf-2
endif

ifneq (x$(USE_POSITION_INDEPENDENT_CODE),x0)
CFLAGS += -fPIC
endif
CFLAGS += -flto
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DMINGW_HAS_SECURE_API -DUNICODE -D_UNICODE -DNO_STRICT
CFLAGS += -DUSING_TP_STUB
CFLAGS += -MMD -MF $(patsubst %$(OBJECT_EXTENSION),%$(DEP_EXTENSION),$@)
CXXFLAGS += $(CFLAGS) -fpermissive
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += $(OPTFLAGS) -static -static-libstdc++ -static-libgcc -Wl,--kill-at -fPIC
LDFLAGS_LIB += -shared
LDLIBS += 

ifneq (x$(USE_TVPSND),x0)
LDLIBS += -luuid
endif

%$(OBJECT_EXTENSION): %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) $(OPTFLAGS) -o $@ $<

%$(OBJECT_EXTENSION): %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) $(OPTFLAGS) -o $@ $<

%$(OBJECT_EXTENSION): %.nas
	@printf '\t%s %s\n' ASM $<
	$(ASM) $(ASMFLAGS) $< -o$@ 

%$(OBJECT_EXTENSION): %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

%.c: %.y
	@printf '\t%s %s\n' YACC $<
	$(YACC) -o $@ $<

PROJECT_BASENAME ?= unknown
ifeq (x$(TARGET_ARCH),xintel32)
BINARY ?= $(PROJECT_BASENAME)_unstripped.dll
endif
BINARY ?= $(PROJECT_BASENAME)_$(TARGET_ARCH)_unstripped.dll
ifeq (x$(TARGET_ARCH),xintel32)
BINARY_STRIPPED ?= $(PROJECT_BASENAME).dll
endif
BINARY_STRIPPED ?= $(PROJECT_BASENAME)_$(TARGET_ARCH).dll
ifneq (x$(USE_ARCHIVE_HAS_GIT_TAG),x0)
ARCHIVE ?= $(PROJECT_BASENAME).$(TARGET_ARCH).$(GIT_TAG).7z
endif
ARCHIVE ?= $(PROJECT_BASENAME).$(TARGET_ARCH).7z

export RC_URL ?= https://github.com/krkrz/$(PROJECT_BASENAME)
export RC_COMMENTS ?= Source code for the latest version of this product is located on the World Wide Web at $(RC_URL)
export RC_DESC ?= $(PROJECT_BASENAME) Plugin for TVP(KIRIKIRI) (2/Z)
export RC_INTERNALNAME ?= $(PROJECT_BASENAME)
export RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2021; See details of license at license.txt, or the source code location.
export RC_ORIGINALFILENAME ?= $(BINARY_STRIPPED)
export RC_PRODUCTNAME ?= $(PROJECT_BASENAME) Plugin for TVP(KIRIKIRI) (2/Z)

WINDRESFLAGS +=  

SOURCES += $(TP_STUB_BASE)/tp_stub.cpp $(TP_STUB_BASE)/common.rc
ifneq (x$(USE_TVPSND),x0)
SOURCES += $(TP_STUB_BASE)/tvpsnd.c
endif
OBJECTS := $(SOURCES:.y=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.c=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.cpp=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.nas=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.rc=$(OBJECT_EXTENSION))
DEPENDENCIES := $(OBJECTS:%$(OBJECT_EXTENSION)=%$(DEP_EXTENSION))

.PHONY:: all archive clean

all: $(BINARY_STRIPPED)

archive: $(ARCHIVE)

clean::
	rm -f $(OBJECTS) $(OBJECTS_BIN) $(BINARY) $(BINARY_STRIPPED) $(ARCHIVE) $(TP_STUB_BASE)/common_ppdefs.rc $(DEPENDENCIES) $(patsubst %.y,%.c,$(filter %.y,$(SOURCES)))

$(TP_STUB_BASE)/common.rc: $(TP_STUB_BASE)/common_ppdefs.rc

$(TP_STUB_BASE)/common_ppdefs.rc:
	@printf '#define RC_URL "%s"'"\n"'#define RC_COMMENTS "%s"'"\n"'#define RC_DESC "%s"'"\n"'#define RC_INTERNALNAME "%s"'"\n"'#define RC_LEGALCOPYRIGHT "%s"'"\n"'#define RC_ORIGINALFILENAME "%s"'"\n"'#define RC_PRODUCTNAME "%s"\n#define GIT_TAG "%s"'"\n"  "$${RC_URL}" "$${RC_COMMENTS}" "$${RC_DESC}" "$${RC_INTERNALNAME}" "$${RC_LEGALCOPYRIGHT}" "$${RC_ORIGINALFILENAME}" "$${RC_PRODUCTNAME}" "$${GIT_TAG}" > $@

$(ARCHIVE): $(BINARY_STRIPPED) $(EXTRA_DIST)
	@printf '\t%s %s\n' 7Z $@
	rm -f $(ARCHIVE)
	$(7Z) a $@ $^

$(BINARY_STRIPPED): $(BINARY)
	@printf '\t%s %s\n' STRIP $@
	$(STRIP) -o $@ $^

$(BINARY): $(OBJECTS)
	@printf '\t%s %s\n' LNK $@
	$(CXX) $(CFLAGS) $(LDFLAGS) $(LDFLAGS_LIB) -o $@ $^ $(LDLIBS)

-include $(DEPENDENCIES)
