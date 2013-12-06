#include "bitmap.h"
#include "binding.hxx"
#include "color.h"
#include "plane.h"
#include "tone.h"

#include <mruby/variable.h>

namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value const self) {
	mrb_value v; // TODO: viewport
	mrb_get_args(M, "|o", &v);
	return init_ptr<Plane>(M, self, new Plane()), self;
}

mrb_value viewport(mrb_state*, mrb_value) {
	return mrb_nil_value(); // TODO
}

mrb_value get_bitmap(mrb_state* M, mrb_value const self) {
	return mrb_iv_get(M, self, mrb_intern_lit(M, "@bitmap"));
}
mrb_value set_bitmap(mrb_state* M, mrb_value const self) {
	mrb_value bmp;
	mrb_get_args(M, "o", &bmp);
	mrb_iv_set(M, self, mrb_intern_lit(M, "@bitmap"), bmp);
	return get<Plane>(M, self).SetBitmap(get_ptr<Bitmap>(M, bmp)), self;
}

mrb_value get_visible(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<Plane>(M, self).visible);
}
mrb_value set_visible(mrb_state* M, mrb_value const self) {
	mrb_bool v;
	mrb_get_args(M, "b", &v);
	return get<Plane>(M, self).visible = v, self;
}

mrb_value get_z(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Plane>(M, self).GetZ());
}
mrb_value set_z(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return get<Plane>(M, self).SetZ(v), self;
}

mrb_value get_ox(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Plane>(M, self).GetOx());
}
mrb_value set_ox(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return get<Plane>(M, self).SetOx(v), self;
}

mrb_value get_oy(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Plane>(M, self).GetOy());
}
mrb_value set_oy(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return get<Plane>(M, self).SetOy(v), self;
}

mrb_value get_zoom_x(mrb_state* M, mrb_value const self) {
	return mrb_float_value(M, get<Plane>(M, self).GetZoomX());
}
mrb_value set_zoom_x(mrb_state* M, mrb_value const self) {
	mrb_float v;
	mrb_get_args(M, "f", &v);
	return get<Plane>(M, self).SetZoomX(v), self;
}

mrb_value get_zoom_y(mrb_state* M, mrb_value const self) {
	return mrb_float_value(M, get<Plane>(M, self).GetZoomY());
}
mrb_value set_zoom_y(mrb_state* M, mrb_value const self) {
	mrb_float v;
	mrb_get_args(M, "f", &v);
	return get<Plane>(M, self).SetZoomY(v), self;
}

mrb_value get_opacity(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Plane>(M, self).GetOpacity());
}
mrb_value set_opacity(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	v = std::max(0, std::min(v, 255));
	Plane& p = get<Plane>(M, self);
	return p.SetOpacity(v), mrb_fixnum_value(p.GetOpacity());
}

mrb_value get_blend_type(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<Plane>(M, self).GetBlendType());
}
mrb_value set_blend_type(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return get<Plane>(M, self).SetBlendType(v), self;
}

mrb_value get_color(mrb_state* M, mrb_value const self) {
	return clone(M, get<Plane>(M, self).GetBlendColor());
}
mrb_value set_color(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return get<Plane>(M, self).SetBlendColor(get<Color>(M, v)), v;
}

mrb_value get_tone(mrb_state* M, mrb_value const self) {
	return clone(M, get<Plane>(M, self).GetTone());
}
mrb_value set_tone(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return get<Plane>(M, self).SetTone(get<Tone>(M, v)), v;
}

}

void EasyRPG::register_plane(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_OPT(1) },
		{ "viewport", &viewport, MRB_ARGS_NONE() },
		property_methods(bitmap), property_methods(visible),
		property_methods(z),
		property_methods(ox), property_methods(oy),
		property_methods(zoom_x), property_methods(zoom_y),
		property_methods(opacity), property_methods(blend_type),
		property_methods(color), property_methods(tone),
		method_info_end };
	register_methods(M, define_class<Plane>(M, "Plane"), methods);
}
