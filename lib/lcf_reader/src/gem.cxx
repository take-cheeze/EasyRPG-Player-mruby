#include <mruby.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include <mruby/string.h>

#include "binding.hxx"
#include "lcf_reader.hxx"
#include "lcf_sym.hxx"

#include <fstream>

namespace EasyRPG {

mrb_value to_mrb(mrb_state* M, LCF::element const& e, picojson_string const& t) {
	using namespace LCF::sym;

	if(t == integer) {
		return mrb_fixnum_value(e.i());
	} else if(t == bool_) {
		return mrb_bool_value(e.b());
	} else if(t == float_) {
		return mrb_float_value(M, e.f());
	} else if(t == string) {
		std::string const str = e.s();
		return mrb_str_new(M, str.data(), str.size());
	} else if(t == event) {
		LCF::event ev = e.e();
		mrb_value const ret = mrb_ary_new_capa(M, ev.size());
		for(LCF::event::iterator i = ev.begin(); i < ev.end(); ++i) {
			mrb_ary_push(M, ret, swap(M, *i));
		}
		return ret;
	} else if(t == int8array) { return clone(M, e.i8a());
	} else if(t == int16array) { return clone(M, e.i16a());
	} else if(t == int32array) { return clone(M, e.i32a());
	} else if(t == map_tree) { return clone(M, e.mt());
	} else if(t == ber_array) { return to_mrb_ary(M, e.ba());
	} else if(t == array1d) { return clone(M, e.a1d());
	} else if(t == array2d) { return clone(M, e.a2d());
	} else {
		picojson const& sch = LCF::get_schema(t);
		if(not sch.is<picojson::null>()) {
			return to_mrb(M, e, sch[type].s());
		}

		assert(false);
		return mrb_nil_value();
	}
}
mrb_value to_mrb(mrb_state* M, LCF::element const& e) {
	return to_mrb(M, e, e.type());
}

mrb_value to_mrb(mrb_state* mrb, picojson::value const& json);

mrb_value to_mrb(mrb_state* mrb, picojson::array const& ary) {
	mrb_value ret = mrb_ary_new_capa(mrb, ary.size());
	for(size_t i = 0; i < ary.size(); ++i) {
		mrb_ary_set(mrb, ret, i, to_mrb(mrb, ary[i]));
	}
	return ret;
}
mrb_value to_mrb(mrb_state* mrb, picojson::object const& obj) {
	mrb_value ret = mrb_hash_new_capa(mrb, obj.size());
	for(picojson::object::const_iterator i = obj.begin(); i != obj.end(); ++i) {
		mrb_hash_set(mrb, ret, mrb_symbol_value(mrb_intern(mrb, i->first.get().c_str())),
					 to_mrb(mrb, i->second));
	}
	return ret;
}
mrb_value to_mrb(mrb_state* M, double const& d) {
	return (d == std::floor(d))
			? mrb_fixnum_value(d) : mrb_float_value(M, d);
}

mrb_value to_mrb(mrb_state* mrb, picojson::value const& json) {
	return
			json.is<picojson::null>()? mrb_nil_value():
			json.is<double>()? to_mrb(mrb, json.get<double>()):
			json.is<bool>()? mrb_bool_value(json.get<bool>()):
			json.is<std::string>()? to_mrb(mrb, json.get<std::string>()):
			json.is<picojson::array>()? to_mrb(mrb, json.get<picojson::array>()):
			json.is<picojson::object>()? to_mrb(mrb, json.get<picojson::object>()):
			(mrb_raise(mrb, E_RUNTIME_ERROR, "unknown picojson type"), mrb_nil_value());
}

void to_cxx(mrb_state* mrb, mrb_value const& v, picojson::value& ret) {
	switch(mrb_type(v)) {
		case MRB_TT_FALSE: ret = picojson::value(false); break;
		case MRB_TT_TRUE: ret = picojson::value(true); break;
		case MRB_TT_FIXNUM: ret = picojson::value(double(mrb_fixnum(v))); break;
		case MRB_TT_SYMBOL: ret = picojson::value(mrb_sym2name(mrb, mrb_symbol(v))); break;
		case MRB_TT_STRING: ret = picojson::value(to_cxx_str(mrb, v)); break;
		case MRB_TT_FLOAT: ret = picojson::value(double(mrb_float(v))); break;
		case MRB_TT_ARRAY: {
			picojson::value(picojson::array_type, bool()).swap(ret);
			picojson::array& ary = ret.get<picojson::array>();
			ary.resize(RARRAY_LEN(v));
			for(size_t i = 0; i < ary.size(); ++i) {
				to_cxx(mrb, RARRAY_PTR(v)[i], ary[i]);
			}
		} break;
		case MRB_TT_HASH: {
			picojson::value(picojson::object_type, bool()).swap(ret);
			picojson::object& obj = ret.get<picojson::object>();
			mrb_value keys = mrb_hash_keys(mrb, v);
			for(mrb_int i = 0; i < RARRAY_LEN(keys); ++i) {
				mrb_value const& k = RARRAY_PTR(keys)[i];
				to_cxx(mrb, mrb_hash_get(mrb, v, k),
					   obj[picojson_string(to_cxx_str(mrb, mrb_str_to_str(mrb, k)))]);
			}
		} break;
		default:
			if(mrb_respond_to(mrb, v, mrb_intern(mrb, "to_picojson"))) {
				to_cxx(mrb, mrb_funcall(mrb, v, "to_picojson", 0), ret);
			} else {
				mrb_raisef(mrb, mrb_class_get(mrb, "TypeError"),
						   "unsupported data type: %s", mrb_obj_classname(mrb, v));
				ret = picojson::value();
			}
	}
}

}

namespace {

using namespace EasyRPG;

template<class T>
mrb_value to_json_func(mrb_state* M, mrb_value const self) {
	picojson json;
	get<T>(M, self).to_json(json);
	return to_mrb(M, json);
}

template<class T>
struct array_methods {
	typedef LCF::detail::array<T> array_type;

	static mrb_value get(mrb_state* M, mrb_value const self) {
		mrb_int v;
		mrb_get_args(M, "i", &v);
		return mrb_fixnum_value(EasyRPG::get<array_type>(M, self)[v]);
	}
	static mrb_value length(mrb_state* M, mrb_value const self) {
		return mrb_fixnum_value(EasyRPG::get<array_type>(M, self).size());
	}
	static mrb_value to_ary(mrb_state* M, mrb_value const self) {
		array_type const& src = EasyRPG::get<array_type>(M, self);
		mrb_value const ret = mrb_ary_new_capa(M, src.size());
		for(size_t i = 0; i < src.size(); ++i) {
			mrb_ary_push(M, ret, mrb_fixnum_value(src[i]));
		}
		return ret;
	}

	static void register_(mrb_state* M, RClass* mod, char const* name) {
		method_info const methods[] = {
			{ "[]", &get, MRB_ARGS_REQ(1) },
			{ "length", &length, MRB_ARGS_NONE() },
			{ "to_ary", &to_ary, MRB_ARGS_NONE() },
			method_info_end };
		register_methods(M, define_class<array_type>(M, name, mod), methods);
	}
};

mrb_value lcf_file_initialize(mrb_state* M, mrb_value const self) {
	char* str; int str_len;
	mrb_get_args(M, "s", &str, &str_len);
	new(data_make_struct<LCF::lcf_file>(M, self)) LCF::lcf_file(std::string(str, str_len));
	return self;
}

mrb_value lcf_file_root(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i",&v);
	return to_mrb(M, get<LCF::lcf_file>(M, self).root(v));
}

mrb_value lcf_file_valid(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<LCF::lcf_file>(M, self).valid());
}

mrb_value lcf_file_get(mrb_state* M, mrb_value const self) {
	mrb_value tmp_v;
	mrb_get_args(M, "o", &tmp_v);
	if(mrb_fixnum_p(tmp_v)) {
		mrb_int v;
		mrb_get_args(M, "i", &v);
		return clone_opt(M, get<LCF::lcf_file>(M, self).get(v));
	} else {
		mrb_sym sym; size_t str_len;
		mrb_get_args(M, "n", &sym);
		char const* const str = mrb_sym2name_len(M, sym, &str_len);
		return to_mrb_opt(M, get<LCF::lcf_file>(M, self).get(picojson_string(str, str_len)));
	}
}

mrb_value lcf_file_error(mrb_state* M, mrb_value const self) {
	std::string const& err = get<LCF::lcf_file>(M, self).error();
	return err.empty()? mrb_nil_value() : to_mrb(M, err);
}

mrb_value array1d_method_missing(mrb_state* M, mrb_value const self) {
	mrb_sym sym; size_t str_len;
	mrb_get_args(M, "n", &sym);
	char const* const str = mrb_sym2name_len(M, sym, &str_len);
	boost::optional<LCF::element> const ret =
			get<LCF::array1d>(M, self).get(picojson_string(str, str_len));
	if(ret) return to_mrb(M, *ret);

	mrb_name_error(M, sym, "%S not found", mrb_sym2str(M, sym));
	return self;
}

mrb_value array1d_get(mrb_state* M, mrb_value const self) {
	mrb_value tmp_v;
	mrb_get_args(M, "o", &tmp_v);
	if(mrb_fixnum_p(tmp_v)) {
		mrb_int v;
		mrb_get_args(M, "i", &v);
		return to_mrb_opt(M, get<LCF::array1d>(M, self).get(v));
	} else {
		mrb_sym sym; size_t str_len;
		mrb_get_args(M, "n", &sym);
		char const* const str = mrb_sym2name_len(M, sym, &str_len);
		return to_mrb_opt(M, get<LCF::array1d>(M, self).get(picojson_string(str, str_len)));
	}
}

mrb_value array1d_index(mrb_state* M, mrb_value const self) {
	LCF::array1d& v = get<LCF::array1d>(M, self);
	return v.is_a2d()? mrb_fixnum_value(v.index()) : mrb_nil_value();
}

mrb_value array1d_is_array2d(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<LCF::array1d>(M, self).is_a2d());
}
mrb_value array1d_is_valid(mrb_state* M, mrb_value const self) {
	return mrb_bool_value(get<LCF::array1d>(M, self).is_valid());
}

mrb_value array2d_get(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return clone_opt(M, get<LCF::array2d>(M, self).get(v));
}

mrb_value array2d_keys(mrb_state* M, mrb_value const self) {
	LCF::array2d const& ary2d = get<LCF::array2d>(M, self);
	mrb_value const ret = mrb_ary_new_capa(M, ary2d.size());
	for(LCF::array2d::const_iterator i = ary2d.begin(); i != ary2d.end(); ++i) {
		mrb_ary_push(M, ret, mrb_fixnum_value(i->first));
	}
	return ret;
}

mrb_value map_tree_get(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return mrb_fixnum_value(get<LCF::map_tree>(M, self)[v]);
}
mrb_value map_tree_active_node(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<LCF::map_tree>(M, self).active_node);
}
mrb_value map_tree_length(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<LCF::map_tree>(M, self).size());
}

mrb_value event_command_code(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<LCF::event_command>(M, self).code);
}
mrb_value event_command_nest(mrb_state* M, mrb_value const self) {
	return mrb_fixnum_value(get<LCF::event_command>(M, self).nest);
}
mrb_value event_command_str(mrb_state* M, mrb_value const self) {
	return to_mrb(M, get<LCF::event_command>(M, self).str);
}
mrb_value event_command_args(mrb_state* M, mrb_value const self) {
	return to_mrb_ary(M, get<LCF::event_command>(M, self).args);
}
mrb_value event_command_get(mrb_state* M, mrb_value const self) {
	mrb_int v;
	mrb_get_args(M, "i", &v);
	return mrb_fixnum_value(get<LCF::event_command>(M, self).args[v]);
}

mrb_value save_lcf(mrb_state* M, mrb_value) {
	mrb_value v; char* str;
	mrb_get_args(M, "oz", &v, &str);
	picojson json;
	to_cxx(M, v, json);
	std::ofstream ofs(str, std::ios::out | std::ios::binary);
	return mrb_bool_value(LCF::save_lcf(json, ofs));
}

}

extern "C" void mrb_lcf_reader_gem_init(mrb_state* M) {
	static method_info const lcf_methods[] = {
		{ "save_lcf", &save_lcf, MRB_ARGS_REQ(2) },
		method_info_end };
	RClass* const mod = define_module(M, "LCF", lcf_methods);

	static method_info const lcf_file_methods[] = {
		{ "initialize", &lcf_file_initialize, MRB_ARGS_REQ(1) },
		{ "root", &lcf_file_root, MRB_ARGS_REQ(1) },
		{ "valid?", &lcf_file_valid, MRB_ARGS_NONE() },
		{ "[]", &lcf_file_get, MRB_ARGS_REQ(1) },
		{ "to_json", &to_json_func<LCF::lcf_file>, MRB_ARGS_NONE() },
		{ "error", &lcf_file_error, MRB_ARGS_NONE() },
		method_info_end };
	register_methods(M, define_class<LCF::lcf_file>(M, "LcfFile", mod), lcf_file_methods);

	static method_info const array1d_methods[] = {
		{ "method_missing", &array1d_method_missing, MRB_ARGS_REQ(1) | MRB_ARGS_REST() },
		{ "[]", &array1d_get, MRB_ARGS_REQ(1) },
		{ "index", &array1d_index, MRB_ARGS_NONE() },
		{ "array2d?", &array1d_is_array2d, MRB_ARGS_NONE() },
		{ "valid?", &array1d_is_valid, MRB_ARGS_NONE() },
		{ "to_json", &to_json_func<LCF::array1d>, MRB_ARGS_NONE() },
		method_info_end };
	register_methods(M, define_class<LCF::array1d>(M, "Array1d", mod), array1d_methods);

	static method_info const array2d_methods[] = {
		{ "[]", &array2d_get, MRB_ARGS_REQ(1) },
		{ "keys", &array2d_keys, MRB_ARGS_NONE() },
		{ "to_json", &to_json_func<LCF::array2d>, MRB_ARGS_NONE() },
		method_info_end };
	register_methods(M, define_class<LCF::array2d>(M, "Array2d", mod), array2d_methods);

	static method_info const map_tree_methods[] = {
		{ "[]", &map_tree_get, MRB_ARGS_REQ(1) },
		{ "active_node", &map_tree_active_node, MRB_ARGS_NONE() },
		{ "length", map_tree_length, MRB_ARGS_NONE() },
		method_info_end };
	register_methods(M, define_class<LCF::map_tree>(M, "MapTree", mod), map_tree_methods);

	array_methods<uint8_t>::register_(M, mod, "int8_array");
	array_methods<int16_t>::register_(M, mod, "int16_array");
	array_methods<int32_t>::register_(M, mod, "int32_array");

	static method_info const event_command_methods[] = {
		{ "code", &event_command_code, MRB_ARGS_NONE() },
		{ "nest", &event_command_nest, MRB_ARGS_NONE() },
		{ "str", &event_command_str, MRB_ARGS_NONE() },
		{ "args", &event_command_args, MRB_ARGS_NONE() },
		{ "[]", &event_command_get, MRB_ARGS_REQ(1) },
		method_info_end };
	register_methods(M, define_class<LCF::event_command>(M, "EventCommand", mod),
					 event_command_methods);
}

extern "C" void mrb_lcf_reader_gem_final(mrb_state*) {}
