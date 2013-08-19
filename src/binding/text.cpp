#include "binding.h"
#include "bitmap.h"
#include "text.h"

namespace {

using namespace EasyRPG;

mrb_value draw(mrb_state* M, mrb_value const self) {
	mrb_value* argv; int argc;
	mrb_get_args(M, "*", &argv, &argc);

	mrb_int x, y, aln = Text::AlignLeft;
	char* str; int str_len;
	mrb_value bmp;
	switch(argc) {
		case 4:
		case 5:
			if(mrb_type(argv[3]) == MRB_TT_STRING) {
				mrb_get_args(M, "oiis|i", &bmp, &x, &y, &str, &str_len, &aln);
				Text::Draw(get<Bitmap>(M, bmp), x, y,
						   std::string(str, str_len), Text::Alignment(aln));
				break;
			}

		case 6: {
			mrb_int col;
			mrb_get_args(M, "oiiis|i", &bmp, &x, &y, &col, &str, &str_len, &aln);
			Text::Draw(get<Bitmap>(M, self), x, y, col,
					   std::string(str, str_len), Text::Alignment(aln));
		} break;

		default:
			wrong_argument(M);
			break;
	}
	return self;
}

}

void EasyRPG::register_text(mrb_state* M) {
	static method_info const methods[] = {
		{ "draw", &draw, MRB_ARGS_REQ(4) | MRB_ARGS_OPT(2) },
		method_info_end };
	RClass* const mod = define_module(M, "Text", methods);
	mrb_define_const(M, mod, "AlignLeft", mrb_fixnum_value(Text::AlignLeft));
	mrb_define_const(M, mod, "AlignCenter", mrb_fixnum_value(Text::AlignCenter));
	mrb_define_const(M, mod, "AlignRight", mrb_fixnum_value(Text::AlignRight));
}
