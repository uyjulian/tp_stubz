#############################################
##                                         ##
##    Copyright (C) 2020-2022 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
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
ifeq (x$(TARGET_ARCH),xarm32)
TARGET_CMAKE_SYSTEM_PROCESSOR ?= arm
endif
ifeq (x$(TARGET_ARCH),xarm64)
TARGET_CMAKE_SYSTEM_PROCESSOR ?= arm64
endif
ifeq (x$(TARGET_ARCH),xintel64)
TARGET_CMAKE_SYSTEM_PROCESSOR ?= amd64
endif
TARGET_CMAKE_SYSTEM_PROCESSOR ?= i686
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
CSTDFLAGS ?= -std=gnu11
CXXSTDFLAGS ?= -std=gnu++14
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

DEPENDENCY_SOURCE_DIRECTORY := $(abspath build-source)
DEPENDENCY_BUILD_DIRECTORY := $(abspath build-$(TARGET_ARCH))
DEPENDENCY_OUTPUT_DIRECTORY := $(abspath build-libraries)-$(TARGET_ARCH)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

%$(OBJECT_EXTENSION): %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) $(CSTDFLAGS) $(OPTFLAGS) -o $@ $<

%$(OBJECT_EXTENSION): %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) $(CXXSTDFLAGS) $(OPTFLAGS) -o $@ $<

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
ifeq (x$(TARGET_ARCH),xintel32)
BINARY_STATICLIB ?= lib$(PROJECT_BASENAME).a
endif
BINARY_STATICLIB ?= lib$(PROJECT_BASENAME)_$(TARGET_ARCH).a
ifneq (x$(USE_ARCHIVE_HAS_GIT_TAG),x0)
ARCHIVE ?= $(PROJECT_BASENAME).$(TARGET_ARCH).$(GIT_TAG).7z
endif
ARCHIVE ?= $(PROJECT_BASENAME).$(TARGET_ARCH).7z

export RC_URL ?= https://github.com/krkrz/$(PROJECT_BASENAME)
export RC_COMMENTS ?= Source code for the latest version of this product is located on the World Wide Web at $(RC_URL)
export RC_DESC ?= $(PROJECT_BASENAME) Plugin for TVP(KIRIKIRI) (2/Z)
export RC_INTERNALNAME ?= $(PROJECT_BASENAME)
export RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2022; See details of license at LICENSE, or the source code location.
export RC_ORIGINALFILENAME ?= $(BINARY_STRIPPED)
export RC_PRODUCTNAME ?= $(PROJECT_BASENAME) Plugin for TVP(KIRIKIRI) (2/Z)

WINDRESFLAGS +=  

TVPIF_SOURCES += $(TP_STUB_BASE)/tp_stub.cpp $(TP_STUB_BASE)/common.rc
ifneq (x$(USE_TVPSND),x0)
TVPIF_SOURCES += $(TP_STUB_BASE)/tvpsnd.c
endif

OBJECTS := $(SOURCES)
OBJECTS := $(OBJECTS:.y=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.c=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.cpp=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.nas=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.rc=$(OBJECT_EXTENSION))
DEPENDENCIES := $(OBJECTS:%$(OBJECT_EXTENSION)=%$(DEP_EXTENSION))

TVPIF_OBJECTS := $(TVPIF_SOURCES)
TVPIF_OBJECTS := $(TVPIF_OBJECTS:.y=$(OBJECT_EXTENSION))
TVPIF_OBJECTS := $(TVPIF_OBJECTS:.c=$(OBJECT_EXTENSION))
TVPIF_OBJECTS := $(TVPIF_OBJECTS:.cpp=$(OBJECT_EXTENSION))
TVPIF_OBJECTS := $(TVPIF_OBJECTS:.nas=$(OBJECT_EXTENSION))
TVPIF_OBJECTS := $(TVPIF_OBJECTS:.rc=$(OBJECT_EXTENSION))
TVPIF_DEPENDENCIES := $(TVPIF_OBJECTS:%$(OBJECT_EXTENSION)=%$(DEP_EXTENSION))

.PHONY:: all staticlib archive clean

all: $(BINARY_STRIPPED)

staticlib: $(BINARY_STATICLIB)

archive: $(ARCHIVE)

clean::
	rm -f $(OBJECTS) $(TVPIF_OBJECTS) $(OBJECTS_BIN) $(BINARY) $(BINARY_STRIPPED) $(BINARY_STATICLIB) $(ARCHIVE) $(TP_STUB_BASE)/common_ppdefs.rc $(DEPENDENCIES) $(TVPIF_DEPENDENCIES) $(patsubst %.y,%.c,$(filter %.y,$(SOURCES)))
	rm -rf $(DEPENDENCY_SOURCE_DIRECTORY) $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_SOURCE_DIRECTORY):
	mkdir -p $@

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $@

$(TP_STUB_BASE)/common.rc: $(TP_STUB_BASE)/common_ppdefs.rc

$(TP_STUB_BASE)/common_ppdefs.rc:
	@printf '#define RC_URL "%-80s"'"\n"'#define RC_COMMENTS "%-80s"'"\n"'#define RC_DESC "%-80s"'"\n"'#define RC_INTERNALNAME "%-80s"'"\n"'#define RC_LEGALCOPYRIGHT "%-80s"'"\n"'#define RC_ORIGINALFILENAME "%-80s"'"\n"'#define RC_PRODUCTNAME "%-80s"\n#define GIT_TAG "%-80s"'"\n"  "$${RC_URL}" "$${RC_COMMENTS}" "$${RC_DESC}" "$${RC_INTERNALNAME}" "$${RC_LEGALCOPYRIGHT}" "$${RC_ORIGINALFILENAME}" "$${RC_PRODUCTNAME}" "$${GIT_TAG}" > $@

$(ARCHIVE): $(BINARY_STRIPPED) $(EXTRA_DIST)
	@printf '\t%s %s\n' 7Z $@
	rm -f $(ARCHIVE)
	$(7Z) a $@ $^

$(BINARY_STRIPPED): $(BINARY)
	@printf '\t%s %s\n' STRIP $@
	$(STRIP) -o $@ $^

$(BINARY): $(BINARY_STATICLIB) $(TVPIF_OBJECTS)
	@printf '\t%s %s\n' LNK $@
	$(CXX) $(CFLAGS) $(LDFLAGS) $(LDFLAGS_LIB) -o $@ $^ $(LDLIBS)

$(BINARY_STATICLIB): $(OBJECTS)
	@printf '\t%s %s\n' AR $@
	$(AR) -rcT $@ $^

-include $(DEPENDENCIES)
-include $(TVPIF_DEPENDENCIES)
