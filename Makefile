CFLAGS += \
	-O3 \
	-Wall \
	-Wextra \
	-Werror \
	-fno-omit-frame-pointer \
	-fstack-protector-strong \
	-fstack-clash-protection \
	-flto \
	-g \
	-D_FORTIFY_SOURCE=2

BINNAME = chexdiff

.PHONY: all build clean dist dist-clean

all: build

build: $(BINNAME)

clean:
	rm -f $(BINNAME)

$(BINNAME): chexdiff.c
	zig cc $(CFLAGS) -target native-native-musl -o $(BINNAME) chexdiff.c

dist: build
	strip -s $(BINNAME)
