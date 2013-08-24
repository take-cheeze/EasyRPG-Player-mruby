#include "bitmap.h"
#include "binding.hxx"

namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value const self) {
	mrb_value* argv; int argc;
	mrb_get_args(M, "*", &argv, &argc);
	switch(argc) {
		case 1: {
			char* str; int str_len;
			mrb_get_args(M, "s", &str, &str_len);
			init_ptr<Bitmap>(M, self, Bitmap::Create(std::string(str, str_len)));
		} break;
		case 2: {
			mrb_int w, h;
			mrb_get_args(M, "ii", &w, &h);
			init_ptr<Bitmap>(M, self, Bitmap::Create(w,h ));
		} break;
		default: wrong_argument(M);
	}
	return self;
}

mrb_value width(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Bitmap>(M, self).width());
}
mrb_value height(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Bitmap>(M, self).height());
}

mrb_value rect(mrb_state* M, mrb_value const self) {
	return clone<Rect>(M, get<Bitmap>(M, self).rect());
}

mrb_value blt(mrb_state* M, mrb_value const self) {
	mrb_int x, y, opacity = 255;
	mrb_value bmp, rct;
	mrb_get_args(M, "iioo|i", &x, &y, &bmp, &rct, &opacity);
	get<Bitmap>(M, self).blit(x, y, get<Bitmap>(M, bmp), get<Rect>(M, rct), opacity);
	return self;
}

mrb_value stretch_blt(mrb_state* M, mrb_value const self) {
	mrb_value dst_rect, bmp, src_rect;
	mrb_int opacity = 255;
	mrb_get_args(M, "ooo|i", &dst_rect, &bmp, &src_rect);
	get<Bitmap>(M, self).stretch_blit(
		get<Rect>(M, dst_rect), get<Bitmap>(M, bmp),
		get<Rect>(M, src_rect), opacity);
	return self;
}

mrb_value fill_rect(mrb_state* M, mrb_value const self) {
	mrb_value* argv; int argc;
	switch(mrb_get_args(M, "*", &argv, &argc)) {
		case 5: {
			mrb_int x, y, w, h;
			mrb_value col;
			mrb_get_args(M, "iiiio", &x, &y, &w, &h, &col);
			get<Bitmap>(M, self).fill(Rect(x, y, w, h), get<Color>(M, col));
		} break;
		case 2:
			get<Bitmap>(M, self).fill(get<Rect>(M, argv[0]), get<Color>(M, argv[1]));
			break;
		default: wrong_argument(M);
	}
	return self;
}

mrb_value clear(mrb_state* M, mrb_value const self) {
	return get<Bitmap>(M, self).clear(), self;
}

mrb_value get_pixel(mrb_state* M, mrb_value const self) {
	mrb_int x, y;
	mrb_get_args(M, "ii", &x, &y);
	return clone<Color>(M, get<Bitmap>(M, self).get_pixel(x, y));
}

mrb_value set_pixel(mrb_state* M, mrb_value const self) {
	mrb_int x, y; mrb_value col;
	mrb_get_args(M, "iio", &x, &y, &col);
	return get<Bitmap>(M, self).set_pixel(x, y, get<Color>(M, col)), self;
}

mrb_value hue_change(mrb_state* M, mrb_value const self) {
	mrb_int hue;
	mrb_get_args(M, "i", &hue);
	return get<Bitmap>(M, self).hue_change(hue), self;
}

mrb_value draw_text(mrb_state* M, mrb_value const self) {
	mrb_value* argv; int argc;
	char* str; int str_len;
	mrb_int aln = Text::AlignLeft;
	switch(mrb_get_args(M, "*", &argv, &argc)) {
		case 2:
		case 3:
			if(is<Rect>(M, argv[0])) {
				mrb_value r; char* str; int str_len;
				mrb_get_args(M, "os|i", &r, &str, &str_len, &aln);
				get<Bitmap>(M, self).draw_text(
					get<Rect>(M, r), std::string(str, str_len), Text::Alignment(aln));
				break;
			}
		case 4: {
			mrb_int x, y;
			mrb_get_args(M, "iis|i", &x, &y, &str, &str_len, &aln);
			get<Bitmap>(M, self).draw_text(
				x, y, std::string(str, str_len), Text::Alignment(aln));
			break;
		}
		case 5:
		case 6: {
			mrb_int x, y, w, h;
			mrb_get_args(M, "iiiis|i", &x, &y, &w, &h, &str, &str_len, &aln);
			get<Bitmap>(M, self).draw_text(Rect(x, y, w, h), str, Text::Alignment(aln));
			break;
		}
		default: wrong_argument(M);
	}
	return self;
}

mrb_value draw_text_2k(mrb_state* M, mrb_value const self) {
	mrb_value* argv; int argc;
	mrb_get_args(M, "*", &argv, &argc);
	char* str; int str_len;
	mrb_int aln = Text::AlignLeft, col;
	switch(argc) {
		case 3:
		case 4:
			if(is<Rect>(M, argv[0])) {
				mrb_value r; char* str; int str_len;
				mrb_get_args(M, "osi|i", &r, &str, &str_len, &col, &aln);
				get<Bitmap>(M, self).draw_text(
					get<Rect>(M, r), std::string(str, str_len), col, Text::Alignment(aln));
				break;
			}
		case 5: {
			mrb_int x, y;
			mrb_get_args(M, "iisi|i", &x, &y, &str, &str_len, &col, &aln);
			get<Bitmap>(M, self).draw_text(
				x, y, std::string(str, str_len), col, Text::Alignment(aln));
			break;
		}
		case 6:
		case 7: {
			mrb_int x, y, w, h;
			mrb_get_args(M, "iiiisi|i", &x, &y, &w, &h, &str, &str_len, &col, &aln);
			get<Bitmap>(M, self).draw_text(
				Rect(x, y, w, h), str, col, Text::Alignment(aln));
			break;
		}
	}
	return self;
}

mrb_value text_size(mrb_state* M, mrb_value const self) {
	char* str; int str_len;
	mrb_get_args(M, "s", &str,  &str_len);
	return clone<Rect>(M, get<Bitmap>(M, self).text_size(std::string(str, str_len)));
}

mrb_value get_font(mrb_state*, mrb_value) {
	return mrb_nil_value();
}

mrb_value set_font(mrb_state*, mrb_value) {
	return mrb_nil_value();
}

}

void EasyRPG::register_bitmap(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_ANY() },
		{ "width", &width, MRB_ARGS_NONE() },
		{ "height", &height, MRB_ARGS_NONE() },
		{ "rect", &rect, MRB_ARGS_NONE() },
		{ "blt", &blt, MRB_ARGS_REQ(4) | MRB_ARGS_OPT(1) },
		{ "stretch_blt", &stretch_blt, MRB_ARGS_REQ(3) | MRB_ARGS_OPT(1) },
		{ "fill_rect", &fill_rect, MRB_ARGS_ANY() },
		{ "clear", &clear, MRB_ARGS_NONE() },
		{ "get_pixel", &get_pixel, MRB_ARGS_REQ(2) },
		{ "set_pixel", &set_pixel, MRB_ARGS_REQ(3) },
		{ "hue_change", &hue_change, MRB_ARGS_REQ(1) },
		{ "draw_text", &draw_text, MRB_ARGS_ANY() },
		{ "draw_text_2k", &draw_text_2k, MRB_ARGS_ANY() },
		{ "text_size", &text_size, MRB_ARGS_REQ(1) },
		property_methods(font),
		method_info_end };
	register_methods(M, define_class<Bitmap>(M, "Bitmap"), methods);
}
