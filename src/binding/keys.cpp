#include "input.h"
#include "binding.hxx"

void EasyRPG::register_keys(mrb_state* M) {
	RClass* const mod = mrb_class_get(M, "Input");

#define define_key(name) mrb_define_const(M, mod, #name, mrb_fixnum_value(Input_::name))
	define_key(DOWN);
	define_key(LEFT);
	define_key(RIGHT);
	define_key(UP);
	define_key(A);
	define_key(B);
	define_key(C);
	define_key(X);
	define_key(Y);
	define_key(Z);
	define_key(L);
	define_key(R);
	define_key(SHIFT);
	define_key(CTRL);
	define_key(ALT);
	define_key(F5);
	define_key(F6);
	define_key(F7);
	define_key(F8);
	define_key(F9);
	define_key(DECISION);
	define_key(CANCEL);
	define_key(DEBUG_MENU);
	define_key(DEBUG_THROUGH);
	define_key(TOGGLE_FPS);
	define_key(TAKE_SCREENSHOT);
	define_key(LOG_VIEWER);
#undef define_key
}
