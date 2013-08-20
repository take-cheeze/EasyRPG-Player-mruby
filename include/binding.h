#ifndef EASYRPG_BINDING_H
#define EASYRPG_BINDING_H

#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <mruby/value.h>

#include <boost/mpl/or.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/type_traits/is_base_of.hpp>
#include <boost/type_traits/is_same.hpp>
#include <boost/utility/enable_if.hpp>

#include <cassert>

#include "memory_management.h"

extern "C" {
	void mrb_EasyRPG_Player_gem_init(mrb_state* M);
	void mrb_EasyRPG_Player_gem_final(mrb_state* M);
}

class Bitmap;
class Drawable;

namespace EasyRPG {

void register_audio(mrb_state* M);
void register_bitmap(mrb_state* M);
void register_cache(mrb_state* M);
void register_color(mrb_state* M);
void register_filefinder(mrb_state* M);
void register_font(mrb_state* M);
void register_graphics(mrb_state* M);
void register_image_io(mrb_state* M);
void register_input(mrb_state* M);
void register_keys(mrb_state* M);
void register_output(mrb_state* M);
void register_plane(mrb_state* M);
void register_rect(mrb_state* M);
void register_sprite(mrb_state* M);
void register_text(mrb_state* M);
void register_tilemap(mrb_state* M);
void register_tone(mrb_state* M);
void register_utils(mrb_state* M);
void register_window(mrb_state* M);

template<class T>
struct user_defined_disposable : public boost::mpl::false_ {};

template<class T>
struct is_disposable : public boost::mpl::or_<
	boost::is_base_of<Drawable, T>,
	boost::is_same<T, Bitmap>,
	user_defined_disposable<T> > {};

template<class T> struct mruby_data_type {
	static mrb_data_type data;

	static RClass* get_class(mrb_state* M) {
		assert(data.struct_name);
		return mrb_class_get(M, data.struct_name);
	}
};
template<class T> mrb_data_type mruby_data_type<T>::data = { NULL, NULL };

template<class T, class Enable = void> struct disposer_newer;

template<class T>
EASYRPG_SHARED_PTR<T>& get_ptr(mrb_state* M, mrb_value const& v,
							  typename boost::enable_if<is_disposable<T> >::type* = 0)
{
	static EASYRPG_SHARED_PTR<T> nil_ptr;
	assert(not nil_ptr);
	if(mrb_nil_p(v)) { return nil_ptr; }

	void* const ptr = mrb_data_check_and_get(M, v, &mruby_data_type<T>::data);
	return *reinterpret_cast<EASYRPG_SHARED_PTR<T>*>(ptr);
}

#define Data_Make_Struct(mrb,klass,strct,type,sval,data) do { \
  sval = mrb_malloc(mrb, sizeof(strct));                     \
  { static const strct zero = { 0 }; *sval = zero; };\
  data = Data_Wrap_Struct(mrb,klass,type,sval);\
} while (0)

template<class T, size_t S = sizeof(T)>
void* data_make_struct(mrb_state* M, RClass* cls, RData*& data) {
	void* const ret = mrb_malloc(M, S);
	data = mrb_data_object_alloc(M, cls, ret, &mruby_data_type<T>::data);
	return ret;
}

template<class T>
struct disposer_newer<T, typename boost::enable_if<is_disposable<T> >::type> {
	typedef EASYRPG_SHARED_PTR<T> ptr_type;

	static void deleter(mrb_state* M, void* ptr) {
		ptr_type* const ref = reinterpret_cast<ptr_type*>(ptr);
		if(ref->use_count() > 1)
			mrb_raise(M, mrb_class_get(M, "RuntimeError"), "cannot dispose object");
		ref->~ptr_type();
		mrb_free(M, ptr);
	}

	static mrb_value dispose(mrb_state* M, mrb_value self) {
		ptr_type& ptr = get_ptr<T>(M, self);
		if(ptr) {
			if(ptr.use_count() > 1)
				mrb_raisef(M, mrb_class_get(M, "RuntimeError"), "cannot dispose %s", self);
			ptr.reset();
		}
		return self;
	}
	static mrb_value is_disposed(mrb_state* M, mrb_value self) {
		return mrb_bool_value(bool(get_ptr<T>(M, self)));
	}

	static mrb_value new_(mrb_state* M, mrb_value const self) {
		assert(mrb_type(self) == MRB_TT_CLASS);
		RData* data = NULL;
		void* const ptr =
				data_make_struct<T, sizeof(ptr_type)>(M, mrb_class_ptr(self), data);
		new(ptr) ptr_type();

		mrb_value const ret = mrb_obj_value(data);
		mrb_value* argv; int argc;
		mrb_get_args(M, "*", &argv, &argc);

		mrb_funcall_argv(M, ret, mrb_intern(M, "initialize"), argc, argv);
		return ret;
	}

	static void register_(mrb_state* M, RClass* cls) {
		mrb_define_method(M, cls, "dispose", &dispose, MRB_ARGS_NONE());
		mrb_define_method(M, cls, "disposed?", &is_disposed, MRB_ARGS_NONE());
		mrb_define_class_method(M, cls, "new", &new_, MRB_ARGS_ANY());
	}
};

template<class T>
struct disposer_newer<T, typename boost::disable_if<is_disposable<T> >::type> {
	static void deleter(mrb_state* M, void* ptr) {
		T* const ref = reinterpret_cast<T*>(ptr);
		ref->~T();
		mrb_free(M, ptr);
	}

	static mrb_value new_(mrb_state* M, mrb_value self) {
		assert(mrb_type(self) == MRB_TT_CLASS);
		RData* data = NULL;
		void* const ptr = data_make_struct<T>(M, mrb_class_ptr(self), data);
		(void)ptr; // new(ptr) T();

		mrb_value const ret = mrb_obj_value(data);
		mrb_value* argv; int argc;
		mrb_get_args(M, "*", &argv, &argc);

		mrb_funcall_argv(M, ret, mrb_intern(M, "initialize"), argc, argv);
		return ret;
	}

	static void register_(mrb_state* M, RClass* cls) {
		mrb_define_class_method(M, cls, "new", &new_, MRB_ARGS_ANY());
	}
};

template<class T>
void check_dispose(mrb_state* M, mrb_value const& v) {
	if(mrb_nil_p(v)) {
		mrb_raise(M, mrb_class_get(M, "RuntimeError"), "dereference to nil value");
	}

	if(get_ptr<T>(M, v)) { return; }
	mrb_raisef(M, mrb_class_get(M, "RuntimeError"), "disposed object: %s", v);
}

template<class T>
T& get(mrb_state* M, mrb_value const& v, typename boost::enable_if<is_disposable<T> >::type* = 0) {
	check_dispose<T>(M, v);
	void* const ptr = mrb_data_check_and_get(M, v, &mruby_data_type<T>::data);
	return *(*reinterpret_cast<EASYRPG_SHARED_PTR<T>*>(ptr));
}

template<class T>
T& get(mrb_state* M, mrb_value const& v, typename boost::disable_if<is_disposable<T> >::type* = 0) {
	void* const ptr = mrb_data_check_and_get(M, v, &mruby_data_type<T>::data);
	return *reinterpret_cast<T*>(ptr);
}

template<class T>
bool is(mrb_state* M, mrb_value const& v) {
	return mrb_data_get_ptr(M, v, &mruby_data_type<T>::data);
}

template<class T>
RClass* define_class(mrb_state* M, char const* name, RClass* base) {
	if(not mruby_data_type<T>::data.struct_name) {
		mruby_data_type<T>::data.struct_name = name;
		mruby_data_type<T>::data.dfree = &disposer_newer<T>::deleter;
	} else {
		assert(mruby_data_type<T>::data.struct_name == name);
		assert(mruby_data_type<T>::data.dfree == &disposer_newer<T>::deleter);
	}

	RClass* const ret = mrb_define_class(M, name, base);
	disposer_newer<T>::register_(M, ret);

	return ret;
}
template<class T>
RClass* define_class(mrb_state* M, char const* name) {
	return define_class<T>(M, name, M->object_class);
}

struct method_info {
	char const* name;
	mrb_func_t function;
	mrb_aspec spec;
};

static method_info const method_info_end = { NULL, NULL, MRB_ARGS_NONE() };

#define property_methods(name)						\
	{ #name, &get_ ## name, MRB_ARGS_NONE() },		\
	{ #name "=", &set_ ## name, MRB_ARGS_REQ(1) }	\

inline RClass* register_methods(mrb_state* M, RClass* cls, method_info const* infos) {
	for(; infos->name; ++infos) {
		mrb_define_method(M, cls, infos->name, infos->function, infos->spec);
	}
	return cls;
}

inline RClass* define_module(mrb_state* M, char const* name, method_info const* infos) {
	RClass* const cls = mrb_define_module(M, name);
	for(; infos->name; ++infos) {
		mrb_define_module_function(M, cls, infos->name, infos->function, infos->spec);
	}
	return cls;
}

inline void wrong_argument(mrb_state* M) {
	mrb_raise(M, mrb_class_get(M, "ArgumentError"), "wrong number of arguments");
}

template<class T>
mrb_value clone(mrb_state* M, T const& v, typename boost::disable_if<is_disposable<T> >::type* = 0) {
	RData* data = NULL;
	void* const ptr = data_make_struct<T>(M, mruby_data_type<T>::get_class(M), data);
	new(ptr) T(v);
	return mrb_obj_value(data);
}

template<class T>
mrb_value create(mrb_state* M, EASYRPG_SHARED_PTR<T> const& v, typename boost::enable_if<is_disposable<T> >::type* = 0) {
	if(not v) { return mrb_nil_value(); }

	RData* data = NULL;
	void* const ptr = data_make_struct<T>(M, mruby_data_type<T>::get_class(M), data);
	new(ptr) EASYRPG_SHARED_PTR<T>(v);
	return mrb_obj_value(data);
}

inline mrb_value to_mrb_str(mrb_state* M, std::string const& str) {
	return mrb_str_new(M, str.data(), str.size());
}

inline std::string to_cxx_str(mrb_state* M, mrb_value const& v) {
	mrb_value const str = mrb_any_to_s(M, v);
	return std::string(RSTRING_PTR(str), RSTRING_LEN(str));
}

}

#endif
