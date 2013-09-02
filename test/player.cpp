#include <ciso646>

#include "utils.h"
#include "filefinder.h"
#include "player.h"
#include "font.h"
#include "rect.h"

#include <mruby.h>
#include <mruby/string.h>

namespace {

#define easyrpg_assert(exp)												\
	do {																\
		if(exp) {														\
			mrb_raisef(													\
				M, mrb_class_get(M, "RuntimeError"),					\
				"assertion failed in %S:%S with expression " #exp,		\
				mrb_str_new_cstr(M, __FILE__), mrb_fixnum_value(__LINE__)); \
		}																\
	} while(false)														\

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
	EASYRPG_SHARED_PTR<FileFinder_::ProjectTree> const
			tree = FileFinder(M).CreateProjectTree(".");
	easyrpg_assert(FileFinder(M).IsRPG2kProject(*tree));
}

void CheckIsDirectory(mrb_state* M) {
	easyrpg_assert(FileFinder(M).IsDirectory("."));
}

void CheckEnglishFilename(mrb_state* M) {
	easyrpg_assert(not FileFinder(M).FindImage("Backdrop", "castle").empty());
}

}

extern "C" void mrb_EasyRPG_Player_get_test(mrb_state* M) {
	Player::register_player(M);

	LowerCase(M);
	GetExt(M);
	CheckSize(M);
	CheckIsDirectory(M);
	CheckIsRPG2kProject(M);
	CheckEnglishFilename(M);
}
