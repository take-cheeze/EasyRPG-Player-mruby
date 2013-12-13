#include "font.h"
#include "color.h"
#include "binding.hxx"

namespace {

using namespace EasyRPG;

struct FontHandle {
	std::string name;
	unsigned size;
	bool bold;
	bool italic;

  private:
	std::weak_ptr<Font> impl_;
};

mrb_value set_default_color(mrb_state* M, mrb_value) {
  mrb_value obj;
  mrb_get_args(M, "o", &obj);
  return Font::default_color = get<Color>(M, obj), obj;
}

}

void EasyRPG::register_font(mrb_state* M) {
	static method_info const methods[] = {
		method_info_end };
	RClass* const Font = register_methods(M, define_class<FontHandle>(M, "Font"), methods);

  mrb_define_module_function(M, Font, "default_color=", &set_default_color, MRB_ARGS_REQ(1));

#define define_color(name) \
	mrb_define_const(M, Font, "Color" #name, mrb_fixnum_value(Font::Color ## name))

	define_color(Shadow);
	define_color(Default);
	define_color(Disabled);
	define_color(Critical);
	define_color(Knockout);

#undef define_color
}
