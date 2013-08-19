#include "binding.h"
#include "graphics.h"

namespace {

using namespace EasyRPG;

mrb_value update(mrb_state*, mrb_value const self) {
	return Graphics().Update(), self;
}

mrb_value freeze(mrb_state*, mrb_value const self) {
	return Graphics().Freeze(), self;
}

mrb_value transition(mrb_state* M, mrb_value const self) {
	mrb_raise(M, mrb_class_get(M, "NotImplementedError"), "rgss transition not implemented");
	return self;
}

mrb_value transition_2k(mrb_state* M, mrb_value const self) {
	mrb_int type, dur;
	mrb_bool erase = false;
	mrb_get_args(M, "ii|b", &type, &dur, &erase);
	return Graphics().Transition(Graphics_::TransitionType(type), dur, erase), self;
}

mrb_value frame_reset(mrb_state*, mrb_value const self) {
	return Graphics().FrameReset(), self;
}

mrb_value get_frame_rate(mrb_state*, mrb_value) {
	return mrb_fixnum_value(Graphics().GetFrameRate());
}
mrb_value set_frame_rate(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return Graphics().SetFrameRate(v), self;
}

mrb_value get_frame_count(mrb_state*, mrb_value) {
	return mrb_fixnum_value(Graphics().GetFrameCount());
}
mrb_value set_frame_count(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return Graphics().SetFrameCount(v), self;
}

}

void EasyRPG::register_graphics(mrb_state* M) {
	static method_info const methods[] = {
		{ "update", &update, MRB_ARGS_NONE() },
		{ "freeze", &freeze, MRB_ARGS_NONE() },
		{ "transition", &transition, MRB_ARGS_OPT(3) },
		{ "transition_2k", &transition_2k, MRB_ARGS_REQ(2) | MRB_ARGS_OPT(1) },
		{ "frame_reset", &frame_reset, MRB_ARGS_NONE() },
		property_methods(frame_rate),
		property_methods(frame_count),
		method_info_end };
	define_module(M, "Graphics", methods);
}
