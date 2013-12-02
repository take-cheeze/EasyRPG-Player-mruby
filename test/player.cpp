#include <ciso646>

#include "utils.h"
#include "filefinder.h"
#include "player.h"
#include "font.h"
#include "rect.h"

#include "binding.hxx"

namespace {

void LowerCase(mrb_state* M) {
	easyrpg_assert(Utils::LowerCase("EasyRPG") == "easyrpg");
	easyrpg_assert(Utils::LowerCase("player") == "player");
}

void GetExt(mrb_state* M) {
	// basic usage
	easyrpg_assert(Utils::GetExt("image.png") == "png");
	// only the last extension
	easyrpg_assert(Utils::GetExt("image.tar.gz") == "gz");
	// expect lowered string
	easyrpg_assert(Utils::GetExt("Image.PnG") == "png");
	// return empty string if no extension
	easyrpg_assert(Utils::GetExt("image").empty());
}

void CheckSize(mrb_state* M) {
	Font const& f = *Font::Default();

	easyrpg_assert(f.GetSize("$$").width == 6 * 1);
	easyrpg_assert(f.GetSize("$$a").width == 6 * 2);
	easyrpg_assert(f.GetSize("$a").width == 6 * 2);
	easyrpg_assert(f.GetSize("$.").width == 6 * 2);
	easyrpg_assert(f.GetSize("$$$b").width == 6 * 3);

	easyrpg_assert(f.GetSize("Hello World!").width == 6 * 12);
}

void CheckIsRPG2kProject(mrb_state* M) {
	std::shared_ptr<FileFinder_::ProjectTree> const
			tree = FileFinder(M).CreateProjectTree(getenv("RPG_TEST_GAME_PATH"));
	easyrpg_assert(FileFinder(M).IsRPG2kProject(*tree));
}

void CheckIsDirectory(mrb_state* M) {
	easyrpg_assert(FileFinder(M).IsDirectory("."));
}

void CheckEnglishFilename(mrb_state* M) {
	easyrpg_assert(not FileFinder(M).FindImage("Backdrop", "castle").empty());
}

}

extern "C" void mrb_EasyRPG_Player_gem_test(mrb_state* M) {
	Player::register_player(M);

	FileFinder(M).UpdateRtpPaths();

	LowerCase(M);
	GetExt(M);
	CheckSize(M);
	CheckIsDirectory(M);
	CheckIsRPG2kProject(M);
	CheckEnglishFilename(M);
}
