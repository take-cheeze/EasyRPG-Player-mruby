#include "bitmap.h"
#include "window.h"
#include "binding.hxx"

#include <mruby/variable.h>

namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	mrb_iv_set(M, self, mrb_intern(M, "@windowskin"), mrb_nil_value());
	mrb_iv_set(M, self, mrb_intern(M, "@contents"), mrb_nil_value());
	return init_ptr<Window>(M, self, new Window()), self;
}

mrb_value viewport(mrb_state*, mrb_value) {
	return mrb_nil_value(); // TODO
}

mrb_value update(mrb_state* M, mrb_value const self) {
	return get<Window>(M, self).Update(), self;
}

mrb_value get_windowskin(mrb_state* M, mrb_value const self) {
	return mrb_iv_get(M, self, mrb_intern(M, "@windowskin"));
}
mrb_value set_windowskin(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	BitmapRef const ref = get_ptr<Bitmap>(M, v);
	mrb_iv_set(M, self, mrb_intern(M, "@windowskin"), v);
	get<Window>(M, self).SetWindowskin(ref);
	return v;
}

mrb_value get_contents(mrb_state* M, mrb_value const self) {
	return mrb_iv_get(M, self, mrb_intern(M, "@contents"));
}
mrb_value set_contents(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	BitmapRef const ref = get_ptr<Bitmap>(M, v);
	mrb_iv_set(M, self, mrb_intern(M, "@contents"), v);
	get<Window>(M, self).SetContents(ref);
	return v;
}

mrb_value get_cursor_rect(mrb_state* M, mrb_value const self) {
	return clone(M, get<Window>(M, self).GetCursorRect());
}
mrb_value set_cursor_rect(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return get<Window>(M, self).SetCursorRect(get<Rect>(M, v)), v;
}

mrb_value get_visible(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<Window>(M, self).visible);
}
mrb_value set_visible(mrb_state* M, mrb_value const self) {
	mrb_bool v;
	mrb_get_args(M, "b", &v);
	return get<Window>(M, self).visible = v, mrb_bool_value(v);
}

#define define_bool_property(name, cxx_name)							\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {		\
		return mrb_bool_value(get<Window>(M, self).Get ## cxx_name());	\
	}																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {		\
		mrb_bool v;														\
		mrb_get_args(M, "b", &v);										\
		Window& w = get<Window>(M, self);								\
		return w.Set ## cxx_name(v), mrb_fixnum_value(w.Get ## cxx_name()); \
	}																	\

define_bool_property(stretch, Stretch)
define_bool_property(active, Active)
define_bool_property(pause, Pause)

#undef define_bool_property

#define define_int_property(name, cxx_name)								\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {		\
		return mrb_fixnum_value(get<Window>(M, self).Get ## cxx_name()); \
	}																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {		\
		mrb_int v;														\
		mrb_get_args(M, "i", &v);										\
		Window& w = get<Window>(M, self);								\
		return w.Set ## cxx_name(v), mrb_fixnum_value(w.Get ## cxx_name()); \
	}																	\

define_int_property(x, X)
define_int_property(y, Y)
define_int_property(width, Width)
define_int_property(height, Height)
define_int_property(z, Z)
define_int_property(ox, Ox)
define_int_property(oy, Oy)
define_int_property(opacity, Opacity)
define_int_property(back_opacity, BackOpacity)
define_int_property(contents_opacity, ContentsOpacity)

#undef define_int_property

}

void EasyRPG::register_window(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_OPT(1) },
		{ "viewport", &viewport, MRB_ARGS_NONE() },
		{ "update", &update, MRB_ARGS_NONE() },
		property_methods(windowskin), property_methods(stretch),
		property_methods(contents),
		property_methods(cursor_rect), property_methods(active),
		property_methods(visible), property_methods(pause),
		property_methods(x), property_methods(y),
		property_methods(width), property_methods(height),
		property_methods(z),
		property_methods(ox), property_methods(oy),
		property_methods(opacity),
		property_methods(back_opacity), property_methods(contents_opacity),
		method_info_end };
	register_methods(M, define_class<Window>(M, "Window"), methods);
}
