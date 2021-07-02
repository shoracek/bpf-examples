#include <stdio.h>
#include <stdlib.h>
#include <bpf/libbpf.h>
#include <xdp/libxdp.h>

int detach(int ifindex)
{
	struct xdp_multiprog *mp = NULL;
	int err;

	mp = xdp_multiprog__get_from_ifindex(ifindex);
	if ((err = libxdp_get_error(mp)))
	{
		printf("Cannot detach from %i: %i\n", ifindex, err);
		return 1;
	}
	err = xdp_multiprog__detach(mp);
	xdp_multiprog__close(mp);

	return err;
}

int attach(int ifindex)
{
	struct xdp_program *prog;
	int err;

	prog = xdp_program__open_file("xdp_pass.o", "xdp", NULL);
	err = xdp_program__attach(prog, ifindex, XDP_MODE_NATIVE, 0);
	xdp_program__close(prog);

	return err;
}

int main(int argc, char **argv)
{
	printf("Hello, World!!\n");

	if (argc != 3)
	{
		printf("Usage: ...\n");
		return 1;
	}

	const char *command = argv[1];
	int ifindex = atoi(argv[2]);

	if (strcmp("attach", command) == 0)
	{
		attach(ifindex);
	}
	else if (strcmp("detach", command) == 0)
	{
		detach(ifindex);
	}
	else
	{
		printf("Usage: ...\n");
		return 1;
	}

	return 0;
}