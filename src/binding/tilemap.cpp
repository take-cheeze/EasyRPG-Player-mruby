#include "binding.h"
#include "bitmap.h"
#include "tilemap.h"

#include <mruby/array.h>
#include <mruby/variable.h>


namespace {

using namespace EasyRPG;

mrb_value initialize(mrb_state* M, mrb_value const self) {
	mrb_iv_set(M, self, mrb_intern(M, "@chipset"), mrb_nil_value());
	return new(data_make_struct<Tilemap>(M, self)) Tilemap(), self;
}

template<class T>
mrb_value to_mrb_ary(mrb_state* M, std::vector<T> const& v) {
	mrb_value const ret = mrb_ary_new_capa(M, v.size());
	for(typename std::vector<T>::const_iterator i = v.begin(); i < v.end(); ++i) {
		mrb_ary_push(M, ret, mrb_fixnum_value(*i));
	}
	return ret;
}

template<class T>
std::vector<T> to_cxx_vector(mrb_value* const ary, mrb_int const len) {
	std::vector<T> ret;
	ret.reserve(len);
	for(mrb_int i = 0; i < len; ++i) {
		assert(mrb_fixnum_p(ary[i]));
		ret.push_back(mrb_fixnum(ary[i]));
	}
	return ret;
}

mrb_value get_map_data_down(mrb_state* M, mrb_value const self) {
	return to_mrb_ary(M, get<Tilemap>(M, self).GetMapDataDown());
}
mrb_value set_map_data_down(mrb_state* M, mrb_value const self) {
	mrb_value* ary; mrb_int len;
	mrb_get_args(M, "a", &ary, &len);
	get<Tilemap>(M, self).SetMapDataDown(to_cxx_vector<int16_t>(ary, len));
	return get_map_data_down(M, self);
}

mrb_value get_map_data_up(mrb_state* M, mrb_value const self) {
	return to_mrb_ary(M, get<Tilemap>(M, self).GetMapDataUp());
}
mrb_value set_map_data_up(mrb_state* M, mrb_value const self) {
	mrb_value* ary; mrb_int len;
	mrb_get_args(M, "a", &ary, &len);
	get<Tilemap>(M, self).SetMapDataUp(to_cxx_vector<int16_t>(ary, len));
	return get_map_data_up(M, self);
}

mrb_value get_passable_down(mrb_state* M, mrb_value const self) {
	return to_mrb_ary(M, get<Tilemap>(M, self).GetPassableDown());
}
mrb_value set_passable_down(mrb_state* M, mrb_value const self) {
	mrb_value* ary; mrb_int len;
	mrb_get_args(M, "a", &ary, &len);
	get<Tilemap>(M, self).SetPassableDown(to_cxx_vector<uint8_t>(ary, len));
	return get_passable_down(M, self);
}

mrb_value get_passable_up(mrb_state* M, mrb_value const self) {
	return to_mrb_ary(M, get<Tilemap>(M, self).GetPassableUp());
}
mrb_value set_passable_up(mrb_state* M, mrb_value const self) {
	mrb_value* ary; mrb_int len;
	mrb_get_args(M, "a", &ary, &len);
	get<Tilemap>(M, self).SetPassableUp(to_cxx_vector<uint8_t>(ary, len));
	return get_passable_up(M, self);
}

/*
mrb_value get_properties(mrb_state* M, mrb_value const self) {
	return to_mrb_ary(M, get<Tilemap>(M, self).GetProperties());
}
mrb_value set_properties(mrb_state* M, mrb_value const self) {
	mrb_value* ary; mrb_int len;
	mrb_get_args(M, "a", &ary, &len);
	get<Tilemap>(M, self).SetProperties(to_cxx_vector<int16_t>(ary, len));
	return get_properties(M, self);
}
*/

mrb_value get_chipset(mrb_state* M, mrb_value const self) {
	return mrb_iv_get(M, self, mrb_intern(M, "@chipset"));
}
mrb_value set_chipset(mrb_state* M, mrb_value const self) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	get<Tilemap>(M, self).SetChipset(get_ptr<Bitmap>(M, v));
	return mrb_iv_set(M, self, mrb_intern(M, "@chipset"), v), v;
}

mrb_value get_visible(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<Tilemap>(M, self).GetVisible());
}
mrb_value set_visible(mrb_state* M, mrb_value const self) {
	mrb_bool v;
	mrb_get_args(M, "b", &v);
	return get<Tilemap>(M, self).SetVisible(v), get_visible(M, self);
}

mrb_value substitudte_up(mrb_state* M, mrb_value const self) {
	mrb_int old_id, new_id;
	mrb_get_args(M, "ii", &old_id, &new_id);
	return get<Tilemap>(M, self).SubstituteUp(old_id, new_id), self;
}
mrb_value substitudte_down(mrb_state* M, mrb_value const self) {
	mrb_int old_id, new_id;
	mrb_get_args(M, "ii", &old_id, &new_id);
	return get<Tilemap>(M, self).SubstituteDown(old_id, new_id), self;
}

#define define_int_property(name, cxx_name)								\
	mrb_value get_ ## name(mrb_state* M, mrb_value const self) {		\
		return mrb_fixnum_value(get<Tilemap>(M, self).Get ## cxx_name()); \
	}																	\
	mrb_value set_ ## name(mrb_state* M, mrb_value const self) {		\
		mrb_int v;														\
		mrb_get_args(M, "i", &v);										\
		return get<Tilemap>(M, self).Set ## cxx_name(v), get_ ## name(M, self);	\
	}																	\

define_int_property(ox, Ox)
define_int_property(oy, Oy)
define_int_property(width, Width)
define_int_property(height, Height)
define_int_property(animation_speed, AnimationSpeed)
define_int_property(animation_type, AnimationType)

#undef define_int_property

}

void EasyRPG::register_tilemap(mrb_state* M) {
	static method_info const methods[] = {
		{ "initialize", &initialize, MRB_ARGS_OPT(1) },
		property_methods(chipset),
		property_methods(map_data_down), property_methods(map_data_up),
		property_methods(passable_up), property_methods(passable_down),
		// property_methods(properties),
		property_methods(visible),
		property_methods(ox), property_methods(oy),
		property_methods(width), property_methods(height),
		property_methods(animation_speed), property_methods(animation_type),
		{ "substitudte_down", &substitudte_down, MRB_ARGS_REQ(2) },
		{ "substitudte_up", &substitudte_up, MRB_ARGS_REQ(2) },
		method_info_end };
	register_methods(M, define_class<Tilemap>(M, "Tilemap"), methods);
}
