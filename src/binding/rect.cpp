#include "rect.h"
#include "binding.hxx"

namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value const self) {
	mrb_int x, y, w, h;
	mrb_get_args(M, "iiii", &x, &y, &w, &h);
	return new(data_make_struct<Rect>(M, self)) Rect(x, y, w, h), self;
}

mrb_value set(mrb_state* M, mrb_value const self) {
	mrb_int x, y, w, h;
	mrb_get_args(M, "iiii", &x, &y, &w, &h);
	get<Rect>(M, self).Set(x, y, w, h);
	return self;
}

#define define_property(name)										\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {	\
		return mrb_fixnum_value(get<Rect>(M, self).name);			\
	}																\
																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {	\
		mrb_int v;													\
		mrb_get_args(M, "i", &v);									\
		return mrb_fixnum_value(get<Rect>(M, self).name = v);		\
	}																\

define_property(x)
define_property(y)
define_property(width)
define_property(height)

#undef define_property

}

void EasyRPG::register_rect(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_REQ(4) },
		{ "set", &set, MRB_ARGS_REQ(4) },
		property_methods(x), property_methods(y),
		property_methods(width), property_methods(height),
		method_info_end };
	register_methods(M, define_class_with_copy<Rect>(M, "Rect"), methods);
}
