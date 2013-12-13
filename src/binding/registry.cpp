#include "binding.hxx"
#include "registry.h"

#include <mruby/variable.h>

using namespace EasyRPG;

namespace {

mrb_value read_str_value(mrb_state* M, mrb_value) {
  mrb_value target;
  char* section;
  char* key;
  mrb_get_args(M, "ozz", &target, &section, &key);

  std::string ret;
  if(mrb_fixnum_p(target)) {
    ret = Registry::ReadStrValue(HKEY(mrb_fixnum(target)), section, key);
  } else {
    ret = Registry::ReadStrValue(to_cxx_str(M, target), section, key);
  }
  return ret.empty()? mrb_nil_value() : to_mrb(M, ret);
}

}

void EasyRPG::register_registry(mrb_state* M) {
  static method_info const methods[] = {
    { "read_string_value", &read_str_value, MRB_ARGS_REQ(3) },
    method_info_end };

  RClass* cls = define_module(M, "Registry", methods);

  mrb_mod_cv_set(M, cls, mrb_intern_lit(M, "HKEY_LOCAL_MACHINE"), mrb_fixnum_value(HKEY_LOCAL_MACHINE));
  mrb_mod_cv_set(M, cls, mrb_intern_lit(M, "HKEY_CURRENT_USER"), mrb_fixnum_value(HKEY_CURRENT_USER));
}
