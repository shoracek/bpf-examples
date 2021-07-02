# Common Makefile parts for BPF-building with libbpf
# --------------------------------------------------
# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
#
# This file should be included from your Makefile like:
#  LIB_DIR = ../lib/
#  include $(LIB_DIR)/common.mk
#
# It is expected that you define the variables:
#  BPF_TARGETS and USER_TARGETS
# as a space-separated list
#
BPF_C = ${BPF_TARGETS:=.c}
BPF_OBJ = ${BPF_C:.c=.o}
USER_C := ${USER_TARGETS:=.c}
USER_OBJ := ${USER_C:.c=.o}
BPF_OBJ_INSTALL ?= $(BPF_OBJ)

# Expect this is defined by including Makefile, but define if not
LIB_DIR ?= ../lib
LDLIBS ?= $(USER_LIBS)

include $(LIB_DIR)/defines.mk

# Extend if including Makefile already added some
LIB_OBJS += $(foreach obj,$(UTIL_OBJS),$(LIB_DIR)/util/$(obj))

EXTRA_DEPS +=
EXTRA_USER_DEPS +=

# BPF-prog kern and userspace shares struct via header file:
KERN_USER_H ?= $(wildcard common_kern_user.h)

CFLAGS += -I$(INCLUDE_DIR) -I$(HEADER_DIR) -I$(LIB_DIR)/util $(EXTRA_CFLAGS)
BPF_CFLAGS += -I$(INCLUDE_DIR) -I$(HEADER_DIR) $(EXTRA_CFLAGS)

BPF_HEADERS := $(wildcard $(HEADER_DIR)/bpf/*.h) $(wildcard $(INCLUDE_DIR)/xdp/*.h)

all: $(USER_TARGETS) $(BPF_OBJ) $(EXTRA_TARGETS)

.PHONY: clean
clean::
	$(Q)rm -f $(USER_TARGETS) $(BPF_OBJ) $(USER_OBJ) $(USER_GEN) *.ll

$(CONFIGMK):
	$(Q)$(MAKE) -C $(LIB_DIR)/.. config.mk

# Create expansions for dependencies
LIB_H := ${LIB_OBJS:.o=.h}

# Detect if any of common obj changed and create dependency on .h-files
$(LIB_OBJS): %.o: %.c %.h $(LIB_H)
	$(Q)$(MAKE) -C $(dir $@) $(notdir $@)

$(USER_TARGETS): %: %.c $(LIBMK) $(LIB_OBJS) $(KERN_USER_H) $(EXTRA_DEPS) $(EXTRA_USER_DEPS)
	$(QUIET_CC)$(CC) -Wall $(CFLAGS) $(LDFLAGS) -o $@ $(LIB_OBJS) \
	 $< $(LDLIBS)

$(BPF_OBJ): %.o: %.c $(KERN_USER_H) $(EXTRA_DEPS) $(BPF_HEADERS) $(LIBMK)
	$(QUIET_CLANG)$(CLANG) -S \
	    -target bpf \
	    -D __BPF_TRACING__ \
	    $(BPF_CFLAGS) \
	    -Wall \
	    -Wno-unused-value \
	    -Wno-pointer-sign \
	    -Wno-compare-distinct-pointer-types \
	    -O2 -emit-llvm -c -g -o ${@:.o=.ll} $<
	$(QUIET_LLC)$(LLC) -march=bpf -filetype=obj -o $@ ${@:.o=.ll}
