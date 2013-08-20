#include "binding.h"
#include "input.h"

namespace {

using namespace EasyRPG;

mrb_value update(mrb_state* M, mrb_value const self) {
	return Input(M).Update(), self;
}

mrb_value triggered(mrb_state* M, mrb_value) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return mrb_bool_value(Input(M).IsTriggered(Input_::Button(v)));
}

mrb_value repeated(mrb_state* M, mrb_value) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return mrb_bool_value(Input(M).IsRepeated(Input_::Button(v)));
}

mrb_value dir4(mrb_state* M, mrb_value) {
	return mrb_fixnum_value(Input(M).dir4);
}
mrb_value dir8(mrb_state* M, mrb_value) {
	return mrb_fixnum_value(Input(M).dir8);
}

}

void EasyRPG::register_input(mrb_state* M) {
	static method_info const methods[] = {
		{ "update", &update, MRB_ARGS_NONE() },
		{ "trigger?", &triggered, MRB_ARGS_REQ(1) },
		{ "repeat?", &repeated, MRB_ARGS_REQ(1) },
		{ "dir4", &dir4, MRB_ARGS_NONE() },
		{ "dir8", &dir8, MRB_ARGS_NONE() },
		method_info_end };
	define_module(M, "Input", methods);
}
