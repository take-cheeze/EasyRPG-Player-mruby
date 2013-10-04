#include "graphics.h"
#include "binding.hxx"

namespace {

using namespace EasyRPG;

mrb_value update(mrb_state* M, mrb_value const self) {
	return Graphics(M).Update(), self;
}

mrb_value freeze(mrb_state* M, mrb_value const self) {
	return Graphics(M).Freeze(), self;
}

mrb_value transition(mrb_state* M, mrb_value const self) {
	mrb_raise(M, mrb_class_get(M, "NotImplementedError"), "rgss transition not implemented");
	return self;
}

mrb_value transition_2k(mrb_state* M, mrb_value const self) {
	mrb_int type, dur;
	mrb_bool erase = false;
	mrb_get_args(M, "ii|b", &type, &dur, &erase);
	return Graphics(M).Transition(Graphics_::TransitionType(type), dur, erase), self;
}

mrb_value frame_reset(mrb_state* M, mrb_value const self) {
	return Graphics(M).FrameReset(), self;
}

mrb_value get_frame_rate(mrb_state* M, mrb_value) {
	return mrb_fixnum_value(Graphics(M).GetFrameRate());
}
mrb_value set_frame_rate(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return Graphics(M).SetFrameRate(v), self;
}

mrb_value get_frame_count(mrb_state* M, mrb_value) {
	return mrb_fixnum_value(Graphics(M).GetFrameCount());
}
mrb_value set_frame_count(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return Graphics(M).SetFrameCount(v), self;
}

mrb_value graphics_pop(mrb_state* M, mrb_value const self) {
	return Graphics(M).Pop(), self;
}

}

void EasyRPG::register_graphics(mrb_state* M) {
	static method_info const methods[] = {
		{ "update", &update, MRB_ARGS_NONE() },
		{ "freeze", &freeze, MRB_ARGS_NONE() },
		{ "transition", &transition, MRB_ARGS_OPT(3) },
		{ "transition_2k", &transition_2k, MRB_ARGS_REQ(2) | MRB_ARGS_OPT(1) },
		{ "frame_reset", &frame_reset, MRB_ARGS_NONE() },
		{ "pop", &graphics_pop, MRB_ARGS_NONE() },
		property_methods(frame_rate),
		property_methods(frame_count),
		method_info_end };
	RClass* const mod = define_module(M, "Graphics", methods);

#define define_transition_enum(name) \
	mrb_define_const(M, mod, "Transition" #name, mrb_fixnum_value(Graphics_::Transition ## name))

	define_transition_enum(FadeIn);
	define_transition_enum(FadeOut);
	define_transition_enum(RandomBlocks);
	define_transition_enum(RandomBlocksUp);
	define_transition_enum(RandomBlocksDown);
	define_transition_enum(BlindOpen);
	define_transition_enum(BlindClose);
	define_transition_enum(VerticalStripesIn);
	define_transition_enum(VerticalStripesOut);
	define_transition_enum(HorizontalStripesIn);
	define_transition_enum(HorizontalStripesOut);
	define_transition_enum(BorderToCenterIn);
	define_transition_enum(BorderToCenterOut);
	define_transition_enum(CenterToBorderIn);
	define_transition_enum(CenterToBorderOut);
	define_transition_enum(ScrollUpIn);
	define_transition_enum(ScrollDownIn);
	define_transition_enum(ScrollLeftIn);
	define_transition_enum(ScrollRightIn);
	define_transition_enum(ScrollUpOut);
	define_transition_enum(ScrollDownOut);
	define_transition_enum(ScrollLeftOut);
	define_transition_enum(ScrollRightOut);
	define_transition_enum(VerticalCombine);
	define_transition_enum(VerticalDivision);
	define_transition_enum(HorizontalCombine);
	define_transition_enum(HorizontalDivision);
	define_transition_enum(CrossCombine);
	define_transition_enum(CrossDivision);
	define_transition_enum(ZoomIn);
	define_transition_enum(ZoomOut);
	define_transition_enum(MosaicIn);
	define_transition_enum(MosaicOut);
	define_transition_enum(WaveIn);
	define_transition_enum(WaveOut);
	define_transition_enum(Erase);
	define_transition_enum(None);

#undef define_transition_enum
}
