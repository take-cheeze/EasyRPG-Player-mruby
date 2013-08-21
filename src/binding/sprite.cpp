#include "binding.h"
#include "bitmap.h"
#include "sprite.h"

#include <mruby/variable.h>

namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value const self) {
	mrb_iv_set(M, self, mrb_intern(M, "@bitmap"), mrb_nil_value());
	return init_ptr<Sprite>(M, self, new Sprite()), self;
}

mrb_value viewport(mrb_state*, mrb_value) {
	return mrb_nil_value();
}

mrb_value flash(mrb_state* M, mrb_value const self) {
	mrb_value col; mrb_int dur;
	mrb_get_args(M, "oi", &col, &dur);
	return get<Sprite>(M, self).Flash(get<Color>(M, col), dur), self;
}

mrb_value get_bitmap(mrb_state* M, mrb_value const self) {
	return mrb_iv_get(M, self, mrb_intern(M, "@bitmap"));
}
mrb_value set_bitmap(mrb_state* M, mrb_value const self) {
	mrb_value bmp;
	mrb_get_args(M, "o", &bmp);
	get<Sprite>(M, self).SetBitmap(get_ptr<Bitmap>(M, bmp));
	return mrb_iv_set(M, self, mrb_intern(M, "@bitmap"), bmp), bmp;
}

mrb_value get_src_rect(mrb_state* M, mrb_value const self) {
	return clone(M, get<Sprite>(M, self).GetSrcRect());
}
mrb_value set_src_rect(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return get<Sprite>(M, self).SetSrcRect(get<Rect>(M, v)), get_src_rect(M, self);
}

mrb_value get_visible(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<Sprite>(M, self).visible);
}
mrb_value set_visible(mrb_state* M, mrb_value const self) {
	mrb_bool v;
	mrb_get_args(M, "b", &v);
	return mrb_bool_value(get<Sprite>(M, self).visible = v);
}

mrb_value get_color(mrb_state* M, mrb_value const self) {
	return clone(M, get<Sprite>(M, self).GetBlendColor());
}
mrb_value set_color(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return get<Sprite>(M, self).SetBlendColor(get<Color>(M, v)), get_color(M, self);
}

mrb_value get_tone(mrb_state* M, mrb_value const self) {
	return clone(M, get<Sprite>(M, self).GetTone());
}
mrb_value set_tone(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return get<Sprite>(M, self).SetTone(get<Tone>(M, v)), get_tone(M, self);
}

mrb_value get_mirror(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<Sprite>(M, self).GetFlipX());
}
mrb_value set_mirror(mrb_state* M, mrb_value const self) {
	mrb_bool v;
	mrb_get_args(M, "b", &v);
	return get<Sprite>(M, self).SetFlipX(v), get_mirror(M, self);
}

mrb_value update(mrb_state* M, mrb_value const self) {
	return get<Sprite>(M, self).Update(), self;
}

#define define_int_property(name, cxx_name)								\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {		\
		return mrb_fixnum_value(get<Sprite>(M, self).Get ## cxx_name()); \
	}																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {		\
		mrb_int v;														\
		mrb_get_args(M, "i", &v);										\
		get<Sprite>(M, self).Set ## cxx_name(v);						\
				return get_ ## name(M, self);							\
	}																	\

define_int_property(x, X)
define_int_property(y, Y)
define_int_property(z, Z)
define_int_property(ox, Ox)
define_int_property(oy, Oy)
define_int_property(bush_depth, BushDepth)
define_int_property(opacity, Opacity)
define_int_property(blend_type, BlendType)

#undef define_int_property

#define define_float_property(name, cxx_name)							\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {		\
		return mrb_float_value(M, get<Sprite>(M, self).Get ## cxx_name()); \
	}																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {		\
		mrb_float v;													\
		mrb_get_args(M, "f", &v);										\
		get<Sprite>(M, self).Set ## cxx_name(v);						\
				return get_ ## name(M, self);							\
	}																	\

define_float_property(zoom_x, ZoomX)
define_float_property(zoom_y, ZoomY)
define_float_property(angle, Angle)

#undef define_float_property

}

void EasyRPG::register_sprite(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_OPT(1) },
		{ "viewport", &viewport, MRB_ARGS_NONE() },
		{ "flash", &flash, MRB_ARGS_REQ(2) },
		{ "update", &update, MRB_ARGS_NONE() },
		property_methods(bitmap), property_methods(src_rect),
		property_methods(visible), property_methods(mirror),
		property_methods(color), property_methods(tone),
		property_methods(x), property_methods(y), property_methods(z),
		property_methods(ox), property_methods(oy),
		property_methods(bush_depth), property_methods(blend_type),
		property_methods(opacity),
		property_methods(zoom_x), property_methods(zoom_y),
		property_methods(angle),
		method_info_end };
	register_methods(M, define_class<Sprite>(M, "Sprite"), methods);
}
