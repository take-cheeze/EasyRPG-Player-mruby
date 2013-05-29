#include <cassert>
#include <cstdlib>
#include "font.h"
#include "rect.h"

namespace {
void CheckSize() {
	Font const& f = *Font::Default();

	assert(f.GetSize("$$").width == 6 * 1);
	assert(f.GetSize("$$a").width == 6 * 2);
	assert(f.GetSize("$a").width == 6 * 2);
	assert(f.GetSize("$.").width == 6 * 2);
	assert(f.GetSize("$$$b").width == 6 * 3);

	assert(f.GetSize("Hello World!").width == 6 * 12);
}
}

int main() {
	CheckSize();
}
