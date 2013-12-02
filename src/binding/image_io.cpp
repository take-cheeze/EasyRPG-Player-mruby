#include "bitmap.h"
#include "image_io.h"
#include "filefinder.h"
#include "binding.hxx"

#include <fstream>

namespace {

using namespace EasyRPG;

#define define_reader(name, cxx_name)									\
	mrb_value read_ ## name(mrb_state* M, mrb_value) {					\
		char* str; int str_len; mrb_bool t;								\
		mrb_get_args(M, "sb", &str, &str_len, &t);						\
																		\
		std::unique_ptr<std::fstream> const is = FileFinder().openUTF8(std::string(str, str_len), \
																		  std::ios::in | std::ios::binary);	\
		if(not is) { return mrb_nil_value(); }							\
																		\
		return create(M, ImageIO::Read ## cxx_name(*is, t));			\
	}																	\

define_reader(bmp, BMP)
define_reader(xyz, XYZ)
define_reader(png, PNG)

#undef define_reader

mrb_value read_image(mrb_state* M, mrb_value) {
	char* str; int str_len; mrb_bool t;
	mrb_get_args(M, "sb", &str, &str_len, &t);
	return create(M, ImageIO::ReadImage(std::string(str, str_len), t));
}

mrb_value write_png(mrb_state* M, mrb_value) {
	mrb_value bmp; char* str; int str_len;
	mrb_get_args(M, "os", &bmp, &str, &str_len);
	return mrb_bool_value(ImageIO::WritePNG(
		get_ptr<Bitmap>(M, bmp), *FileFinder().openUTF8(
			std::string(str, str_len), std::ios::out | std::ios::binary)));
}

}

void EasyRPG::register_image_io(mrb_state* M) {
	static method_info const methods[] = {
		{ "read_bmp", &read_bmp, MRB_ARGS_REQ(2) },
		{ "read_xyz", &read_xyz, MRB_ARGS_REQ(2) },
		{ "read_png", &read_png, MRB_ARGS_REQ(2) },
		{ "read_image", &read_image, MRB_ARGS_REQ(2) },
		{ "write_png", &write_png, MRB_ARGS_REQ(2) },
		method_info_end };
	define_module(M, "ImageIO", methods);
}
