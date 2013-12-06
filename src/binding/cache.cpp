#include "bitmap.h"
#include "cache.h"
#include "binding.hxx"

#include <boost/container/flat_map.hpp>
#include <mruby/variable.h>

namespace {

using namespace EasyRPG;

struct CacheReferenceTable {
	struct value {
		mrb_value ruby_ref;
		std::weak_ptr<Bitmap> cxx_ref;
	};
	mrb_state* M;
	typedef boost::container::flat_map<Bitmap*, value> data_type;
	data_type data;

	mrb_value to_ruby_ref(BitmapRef const& ref) {
		value& i = data[ref.get()];
		if(i.cxx_ref.expired()) { i.ruby_ref = create(M, ref); }
		return i.ruby_ref;
	}

	static CacheReferenceTable& get(mrb_state* M) {
		return EasyRPG::get<CacheReferenceTable>(
			M, mrb_mod_cv_get(M, mrb_class_get(M, "Player"),
							  mrb_intern_lit(M, "_cache_reference_table")));
	}

	static void set(mrb_state* M) {
		RClass* const player = mrb_class_defined(M, "Player")
							   ? mrb_class_get(M, "Player") : mrb_define_module(M, "Player");

		mrb_value const ruby_val = clone<CacheReferenceTable>(M, CacheReferenceTable());
		CacheReferenceTable& v = EasyRPG::get<CacheReferenceTable>(M, ruby_val);
		v.M = M;
		mrb_mod_cv_set(M, player, mrb_intern_lit(M, "_cache_reference_table"), ruby_val);
	}
};

#define define_material(name, cxx_name)						\
	mrb_value name(mrb_state* M, mrb_value) {				\
		char* str; int str_len;								\
		mrb_get_args(M, "s", &str, &str_len);				\
		return  CacheReferenceTable::get(M).to_ruby_ref(	\
			Cache(M).cxx_name(std::string(str, str_len)));	\
	}														\

define_material(backdrop, Backdrop)
define_material(battle, Battle)
define_material(battle2, Battle2)
define_material(battlecharset, Battlecharset)
define_material(battleweapon, Battleweapon)
define_material(charset, Charset)
define_material(faceset, Faceset)
define_material(frame, Frame)
define_material(gameover, Gameover)
define_material(monster, Monster)
define_material(panorama, Panorama)
define_material(picture, Picture)
define_material(chipset, Chipset)
define_material(title, Title)
define_material(system, System)
define_material(system2, System2)

#undef define_material

mrb_value tile(mrb_state* M, mrb_value) {
	char* str; int str_len; mrb_int id;
	mrb_get_args(M, "si", &str, &str_len, &id);
	return CacheReferenceTable::get(M).to_ruby_ref(
		Cache(M).Tile(std::string(str, str_len), id));
}

mrb_value claer(mrb_state* M, mrb_value self) {
	CacheReferenceTable::get(M).data.clear();
	Cache(M).Clear();
	return self;
}

}

void EasyRPG::register_cache(mrb_state* M) {
	static method_info const methods[] = {
		{ "backdrop", &backdrop, MRB_ARGS_REQ(1) },
		{ "battle", &battle, MRB_ARGS_REQ(1) },
		{ "battle2", &battle2, MRB_ARGS_REQ(1) },
		{ "battlecharset", &battlecharset, MRB_ARGS_REQ(1) },
		{ "battleweapon", &battleweapon, MRB_ARGS_REQ(1) },
		{ "charset", &charset, MRB_ARGS_REQ(1) },
		{ "faceset", &faceset, MRB_ARGS_REQ(1) },
		{ "frame", &frame, MRB_ARGS_REQ(1) },
		{ "gameover", &gameover, MRB_ARGS_REQ(1) },
		{ "monster", &monster, MRB_ARGS_REQ(1) },
		{ "panorama", &panorama, MRB_ARGS_REQ(1) },
		{ "picture", &picture, MRB_ARGS_REQ(1) },
		{ "chipset", &chipset, MRB_ARGS_REQ(1) },
		{ "title", &title, MRB_ARGS_REQ(1) },
		{ "system", &system, MRB_ARGS_REQ(1) },
		{ "system2", &system2, MRB_ARGS_REQ(1) },
		{ "tile", &tile, MRB_ARGS_REQ(2) },
		{ "clear", &claer, MRB_ARGS_NONE() },
		method_info_end };
	define_module(M, "Cache", methods);

	define_class<CacheReferenceTable>(M, "_CacheReferenceTable");
	CacheReferenceTable::set(M);
}
