
LIBBPF_CFLAGS:=$(if $(CFLAGS),$(CFLAGS),-g -O2 -Werror -Wall) -fPIC

LIB_DIR = .
include defines.mk

SUBDIRS=

all: xdp_tools_lib
	@set -e; \
	for i in $(SUBDIRS); \
	do echo; echo "  $$i"; $(MAKE) -C $$i; done

xdp_tools_lib:
	@set -e; \
	echo; echo "  xdp-tools"; $(MAKE) -C xdp-tools lib


.PHONY: clean xdp_tools_clean
clean: xdp_tools_clean
	@for i in $(SUBDIRS); \
	do $(MAKE) -C $$i clean; done

xdp_tools_clean:
	@$(MAKE) -C xdp-tools clean
