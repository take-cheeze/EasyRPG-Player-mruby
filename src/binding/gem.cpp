#include "binding.hxx"

namespace {

mrb_value array_index(mrb_state* M, mrb_value const self) {
	mrb_value obj = mrb_undef_value();
	
	mrb_get_args(M, "|o", &obj);
	if(not mrb_undef_p(obj)) {
		for(mrb_int i = 0; i < RARRAY_LEN(self); ++i) {
			if(mrb_equal(M, RARRAY_PTR(self)[i], obj)) {
				return mrb_fixnum_value(i);
			}
		}
	} else {
		mrb_get_args(M, "&", &obj);
		for(mrb_int i = 0; i < RARRAY_LEN(self); ++i) {
			if(mrb_test(mrb_yield(M, obj, RARRAY_PTR(self)[i]))) {
				return mrb_fixnum_value(i);
			}
		}
	}

	return mrb_nil_value();
}

mrb_value array_rindex(mrb_state* M, mrb_value const self) {
	mrb_value obj = mrb_undef_value();
	
	mrb_get_args(M, "|o", &obj);
	if(not mrb_undef_p(obj)) {
		for(mrb_int i = RARRAY_LEN(self) - 1; i >= 0; --i) {
			if(mrb_equal(M, RARRAY_PTR(self)[i], obj)) {
				return mrb_fixnum_value(i);
			}
		}
	} else {
		mrb_get_args(M, "&", &obj);
		for(mrb_int i = RARRAY_LEN(self) - 1; i >= 0; --i) {
			if(mrb_test(mrb_yield(M, obj, RARRAY_PTR(self)[i]))) {
				return mrb_fixnum_value(i);
			}
		}
	}

	return mrb_nil_value();
}

}

extern "C" void mrb_EasyRPG_Player_gem_init(mrb_state* M) {
	EasyRPG::register_audio(M);
	EasyRPG::register_bitmap(M);
	EasyRPG::register_cache(M);
	EasyRPG::register_color(M);
	EasyRPG::register_filefinder(M);
	EasyRPG::register_font(M);
	EasyRPG::register_graphics(M);
	EasyRPG::register_image_io(M);
	EasyRPG::register_input(M);
	EasyRPG::register_keys(M);
	EasyRPG::register_output(M);
	EasyRPG::register_plane(M);
	EasyRPG::register_rect(M);
	EasyRPG::register_sprite(M);
	EasyRPG::register_text(M);
	EasyRPG::register_tilemap(M);
	EasyRPG::register_tone(M);
	EasyRPG::register_utils(M);
	EasyRPG::register_window(M);

	mrb_define_method(M, M->array_class, "index", &array_index, MRB_ARGS_OPT(1) | MRB_ARGS_BLOCK());
	mrb_define_method(M, M->array_class, "rindex", &array_rindex, MRB_ARGS_OPT(1) | MRB_ARGS_BLOCK());
}

extern "C" void mrb_EasyRPG_Player_gem_final(mrb_state*) {}
