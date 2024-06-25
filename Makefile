.SUFFIX:

# Get include path for Erlang, add to CFLAGS
ERLANG_PATH := $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

# Other directory paths
OUT_DIR := priv

LIBMAGIC_PATH := deps/libmagic
LIBMAGIC_VERSION := $(shell cat .file-version)
LIBMAGIC_STAMP := $(OUT_DIR)/libmagic-$(LIBMAGIC_VERSION).stamp


# Set up compiler flags
CFLAGS := -g -O3 -fPIC -Wall -Wno-unused-parameter
CPPFLAGS := -I$(ERLANG_PATH) -I$(LIBMAGIC_PATH)/src
LDFLAGS := -lz #-L$(LIBMAGIC_PATH) -lmagic


############################################################
## PLATFORM-SPECIFIC

ifeq ($(shell uname),Darwin)
LDFLAGS += -undefined dynamic_lookup -dynamiclib
endif

############################################################
## RULES

LIBMAGIC_AR := $(LIBMAGIC_PATH)/src/.libs/libmagic.a

.PHONY: all env clean

all: $(OUT_DIR)/exmagic.so $(OUT_DIR)/magic.mgc

# Note: need to run the build to create the header file
$(OUT_DIR)/exmagic.o: c_src/exmagic.c $(LIBMAGIC_STAMP) | $(OUT_DIR)
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ c_src/exmagic.c

$(OUT_DIR)/exmagic.so: $(OUT_DIR)/exmagic.o $(LIBMAGIC_STAMP) $(LIBMAGIC_AR) | $(OUT_DIR)
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ $(OUT_DIR)/exmagic.o $(LIBMAGIC_AR)

$(LIBMAGIC_STAMP): | $(OUT_DIR)
	if [ ! -d "deps" ]; then mkdir deps; fi
	cd deps; if [ ! -d "libmagic" ]; then git clone https://github.com/file/file.git libmagic; fi ; cd ..
	cd deps/libmagic ; git checkout a0d5b0e
	cd $(LIBMAGIC_PATH) && autoreconf -i
	cd $(LIBMAGIC_PATH) && ./configure \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		CFLAGS="-g -O3 -fPIC"
	$(MAKE) -C $(LIBMAGIC_PATH)
	@touch $@

$(OUT_DIR)/magic.mgc: $(LIBMAGIC_STAMP) | $(OUT_DIR)
	cp $(LIBMAGIC_PATH)/magic/magic.mgc $@

$(OUT_DIR):
	mkdir -p $@

$(LIBMAGIC_AR):
	$(MAKE) -C c_src/libmagic

############################################################
## UTIL

env:
	@echo "CFLAGS           = $(CFLAGS)"
	@echo "CPPFLAGS         = $(CFPPLAGS)"
	@echo "LDFLAGS          = $(LDFLAGS)"
	@echo "ERLANG_PATH      = $(ERLANG_PATH)"
	@echo "OUT_DIR          = $(OUT_DIR)"
	@echo "LIBMAGIC_PATH    = $(LIBMAGIC_PATH)"
	@echo "LIBMAGIC_VERSION = $(LIBMAGIC_VERSION)"

clean:
	$(MAKE) -C $(LIBMAGIC_PATH) clean || true
	$(RM) \
		$(OUT_DIR)/exmagic.so* \
		$(OUT_DIR)/exmagic.o \
		$(OUT_DIR)/*.stamp \
		$(OUT_DIR)/magic.mgc
