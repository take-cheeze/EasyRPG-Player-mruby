#include "binding.h"
#include "color.h"
#include "output.h"

#include <mruby/array.h>
#include <mruby/hash.h>

namespace {

using namespace EasyRPG;

mrb_value take_screenshot(mrb_state* M, mrb_value const self) {
	char* str; int str_len;
	switch(mrb_get_args(M, "|s", &str, &str_len)) {
		case 0: {
			boost::optional<std::string> const ret = Output(M).TakeScreenshot();
			return ret? to_mrb_str(M, *ret) : mrb_nil_value();
		}
		case 1: return mrb_bool_value(Output(M).TakeScreenshot(std::string(str, str_len)));

		default:
			assert(false);
			return self;
	}
}

mrb_value update(mrb_state* M, mrb_value const self) {
	return Output(M).Update(), self;
}

mrb_value type_color(mrb_state* M, mrb_value) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return clone(M, Output(M).TypeColor(Output_::Type(v)));
}

mrb_value type_string(mrb_state* M, mrb_value) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return to_mrb_str(M, Output(M).Type2String(Output_::Type(v)));
}

mrb_value buffer(mrb_state* M, mrb_value) {
	Output_::buffer_type const& buf = Output(M).buffer();
	mrb_value const ret = mrb_ary_new_capa(M, buf.size());
	for(Output_::buffer_type::const_iterator i = buf.begin(); i != buf.end(); ++i) {
		mrb_value const h = mrb_hash_new_capa(M, 4);
		mrb_hash_set(M, h, mrb_symbol_value(mrb_intern(M, "time")),
					 to_mrb_str(M, Output(M).local_time(i->time, true)));
		mrb_hash_set(M, h, mrb_symbol_value(mrb_intern(M, "type")),
					 mrb_fixnum_value(i->type));
		mrb_hash_set(M, h, mrb_symbol_value(mrb_intern(M, "message")),
					 to_mrb_str(M, i->message));
		mrb_hash_set(M, h, mrb_symbol_value(mrb_intern(M, "screenshot")),
					 i->screenshot? to_mrb_str(M, *i->screenshot) : mrb_nil_value());
		mrb_ary_push(M, ret, h);
	}
	return ret;
}

#define define_message(name, cxx_name)					 \
	mrb_value name(mrb_state* M, mrb_value const self) { \
		char* str; int str_len;							 \
		mrb_get_args(M, "s", &str, &str_len);			 \
		Output(M).cxx_name(std::string(str, str_len));	 \
		return self;									 \
	}													 \

define_message(debug, Debug)
define_message(warning, Warning)
define_message(error, Error)

#undef define_message

}

void EasyRPG::register_output(mrb_state* M) {
	mrb_define_class(M, "RGSSError", mrb_class_get(M, "StandardError"));

	static method_info const methods[] = {
		{ "debug", &debug, MRB_ARGS_REQ(1) },
		{ "warning", &warning, MRB_ARGS_REQ(1) },
		{ "error", &error, MRB_ARGS_REQ(1) },
		{ "take_screenshot", &take_screenshot, MRB_ARGS_OPT(1) },
		{ "update", &update, MRB_ARGS_NONE() },
		{ "type_color", &type_color, MRB_ARGS_REQ(1) },
		{ "type_string", &type_string, MRB_ARGS_REQ(1) },
		{ "buffer", &buffer, MRB_ARGS_NONE() },
		method_info_end };
	RClass* const Output = define_module(M, "Output", methods);

	mrb_define_const(M, Output, "DEBUG", mrb_fixnum_value(Output_::TypeDebug));
	mrb_define_const(M, Output, "WARNING", mrb_fixnum_value(Output_::TypeWarning));
	mrb_define_const(M, Output, "ERROR", mrb_fixnum_value(Output_::TypeError));
}
