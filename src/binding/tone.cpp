#include "binding.h"
#include "tone.h"

#include <mruby/variable.h>

namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value self) {
	mrb_float r, g, b, gray = 0;
	mrb_get_args(M, "fff|f", &r, &g, &b, &gray);
	new(&get<Tone>(M, self)) Tone(r, g, b, gray);
	mrb_iv_set(M, self, mrb_intern(M, "@red"), mrb_float_value(M, r));
	mrb_iv_set(M, self, mrb_intern(M, "@green"), mrb_float_value(M, g));
	mrb_iv_set(M, self, mrb_intern(M, "@blue"), mrb_float_value(M, b));
	mrb_iv_set(M, self, mrb_intern(M, "@gray"), mrb_float_value(M, gray));
	return self;
}

mrb_value set(mrb_state* M, mrb_value self) {
	mrb_float r, g, b, gray = 0;
	mrb_get_args(M, "fff|f", &r, &g, &b, &gray);
	Tone& t = get<Tone>(M, self);
	t.red = r; t.green = g; t.blue = b; t.gray = gray;
	mrb_iv_set(M, self, mrb_intern(M, "@red"), mrb_float_value(M, r));
	mrb_iv_set(M, self, mrb_intern(M, "@green"), mrb_float_value(M, g));
	mrb_iv_set(M, self, mrb_intern(M, "@blue"), mrb_float_value(M, b));
	mrb_iv_set(M, self, mrb_intern(M, "@gray"), mrb_float_value(M, gray));
	return self;
}

#define define_property(name)										\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {	\
		return mrb_iv_get(M, self, mrb_intern(M, "@" #name));		\
	}																\
																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {	\
		mrb_float v;												\
		mrb_get_args(M, "f", &v);									\
		v = std::max<mrb_float>(0, std::min<mrb_float>(v, 255));	\
		get<Tone>(M, self).name = v;								\
		mrb_value const ret = mrb_float_value(M, v);				\
		mrb_iv_set(M, self, mrb_intern(M, "@" #name), ret);			\
		return ret;													\
	}																\

define_property(red)
define_property(green)
define_property(blue)
define_property(gray)

#undef define_property

}

void EasyRPG::register_tone(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_REQ(3) | MRB_ARGS_OPT(1) },
		{ "set", &set, MRB_ARGS_REQ(3) | MRB_ARGS_OPT(1) },
		property_methods(red),
		property_methods(green),
		property_methods(blue),
		property_methods(gray),
		method_info_end };
	register_methods(M, define_class<Tone>(M, "Tone"), methods);
}
