#include <ctype.h>
#include <stdio.h>
#include <string.h>

static const char* cReset = "\033[0m";
static const char* cRed = "\033[31m";

typedef struct {
  const char* data;
  size_t size;
} hexstr_t;

static inline int isCharEq(char l, char r) {
  const char magic = 'A' - 'a';
  if (isupper(l)) l -= magic;
  if (isupper(r)) r -= magic;
  return (l == r);
}

static inline int isHexDigitEq(const char* l, const char* r) {
  return (isCharEq(l[0], r[0]) && isCharEq(l[1], r[1]));
}

static inline void hexstr_process(const hexstr_t self, const hexstr_t other) {
  const size_t cmnSize = (self.size < other.size) ? self.size : other.size;
  for (size_t i = 0; i < cmnSize; i += 2) {
    if (isHexDigitEq(self.data + i, other.data + i)) {
      printf("%c%c", self.data[i], self.data[i + 1]);
    } else {
      printf("%s%c%c%s", cRed, self.data[i], self.data[i + 1], cReset);
    }
  }
  if (self.size > other.size) {
    printf("%s%s%s", cRed, self.data + other.size, cReset);
  }
  printf("\n");
}

static const char* usage =
    "usage: chexdiff [options] hex1 hex2\n"
    "\n"
    "Compare the two hex strings and print their differences.\n"
    "\n"
    "options:\n"
    "    -h/--help    print this message\n"
    "    -v           print version\n";

static const char* version = "0.1";

int main(int argc, char* argv[]) {
  const int nargs = argc - 1;
  char** args = argv + 1;

  if (nargs == 0) {
    fprintf(stderr, "%s", usage);
    return 1;
  }

  if (nargs >= 1) {
    if (strncmp(args[0], "-h", 2) == 0 || strncmp(args[0], "--help", 6) == 0) {
      printf("%s", usage);
      return 0;
    }
    if (strncmp(args[0], "-v", 2) == 0) {
      printf("%s\n", version);
      return 0;
    }
  }

  if (nargs != 2) {
    fprintf(stderr,
            "error: wrong number of args, need two: 1st and 2nd hex string\n");
    printf("\n%s", usage);
    return 1;
  }

  const hexstr_t first = {argv[1], strlen(argv[1])};
  if (first.size % 2 != 0) {
    fprintf(stderr, "error: '%s' has invalid length\n", first.data);
    return 1;
  }

  const hexstr_t second = {argv[2], strlen(argv[2])};
  if (second.size % 2 != 0) {
    fprintf(stderr, "error: '%s' has invalid length\n", second.data);
    return 1;
  }

  hexstr_process(first, second);
  hexstr_process(second, first);

  return 0;
}
