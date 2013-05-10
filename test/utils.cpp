#include <cassert>
#include <cstdlib>
#include <SDL.h>

#include "utils.h"


namespace {
void LowerCase() {
	assert(Utils::LowerCase("EasyRPG") == "easyrpg");
	assert(Utils::LowerCase("player") == "player");
}

void GetExt() {
	// basic usage
	assert(Utils::GetExt("image.png") == "png");
	// only the last extension
	assert(Utils::GetExt("image.tar.gz") == "gz");
	// expect lowered string
	assert(Utils::GetExt("Image.PnG") == "png");
	// return empty string if no extension
	assert(Utils::GetExt("image").empty());
}
}


extern "C" int main(int, char**) {
  LowerCase();
  GetExt();

  return EXIT_SUCCESS;
}
