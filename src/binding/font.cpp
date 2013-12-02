#include "font.h"
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

}

void EasyRPG::register_font(mrb_state* M) {
	static method_info const methods[] = {
		method_info_end };
	RClass* const Font = register_methods(M, define_class<FontHandle>(M, "Font"), methods);

#define define_color(name) \
	mrb_define_const(M, Font, "Color" #name, mrb_fixnum_value(Font::Color ## name))

	define_color(Shadow);
	define_color(Default);
	define_color(Disabled);
	define_color(Critical);
	define_color(Knockout);

#undef define_color
}
