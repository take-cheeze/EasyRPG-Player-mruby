#include "filefinder.h"
#include "binding.hxx"

#include <mruby/array.h>
#include <mruby/hash.h>

namespace {

using namespace EasyRPG;

typedef FileFinder_::ProjectTree ProjectTree;

mrb_value find_image(mrb_state* M, mrb_value) {
	char* dir, name; int dir_len, name_len;
	mrb_get_args(M, "ss", &dir, &dir_len, &name, &name_len);
	return to_mrb(M, FileFinder(M).FindImage(std::string(dir, dir_len),
											 std::string(name, name_len)));
}

mrb_value update_rtp_paths(mrb_state* M, mrb_value const self) {
	return FileFinder(M).UpdateRtpPaths(), self;
}

mrb_value find_default(mrb_state* M, mrb_value) {
	char* dir, name; int dir_len, name_len;
	size_t const argc = mrb_get_args(M, "s|s", &dir, &dir_len, &name, &name_len);
	return to_mrb(M, argc == 2
					  ? FileFinder(M).FindDefault(std::string(dir, dir_len),
												 std::string(name, name_len))
					  : FileFinder(M).FindDefault(std::string(dir, dir_len)));
}

mrb_value is_directory(mrb_state* M, mrb_value) {
	char* name; int name_len;
	mrb_get_args(M, "s", &name, &name_len);
	return mrb_bool_value(FileFinder(M).IsDirectory(std::string(name, name_len)));
}

mrb_value exists(mrb_state* M, mrb_value) {
	char* name; int name_len;
	mrb_get_args(M, "s", &name, &name_len);
	return mrb_bool_value(FileFinder(M).Exists(std::string(name, name_len)));
}

mrb_value make_path(mrb_state* M, mrb_value) {
	char* dir; char* name; int dir_len, name_len;
	mrb_get_args(M, "ss", &dir, &dir_len, &name, &name_len);
	return to_mrb(M, FileFinder(M).MakePath(std::string(dir, dir_len),
											   std::string(name, name_len)));
}

typedef FileFinder_::string_map string_map;

string_map hash_to_map(mrb_state* M, mrb_value h) {
	assert(mrb_hash_p(h));

	mrb_value const keys = mrb_hash_keys(M, h);
	FileFinder_::string_map ret;
	ret.reserve(RARRAY_LEN(keys));

	for(mrb_int i = 0; i < RARRAY_LEN(keys); ++i) {
		mrb_value const& key = RARRAY_PTR(keys)[i];
		ret[to_cxx_str(M, key)] = to_cxx_str(M, mrb_hash_get(M, h, key));
	}

	return ret;
}

mrb_value is_rpg2k_project(mrb_state* M, mrb_value) {
	mrb_value v;
	mrb_get_args(M, "o", &v);
	return mrb_bool_value(
      mrb_hash_p(v)? FileFinder(M).IsRPG2kProject(hash_to_map(M, v)):
      mrb_string_p(v)? FileFinder(M).IsRPG2kProject(EasyRPG::to_cxx_str(M, v)):
      FileFinder(M).IsRPG2kProject(get<ProjectTree>(M, v)));
}

mrb_value get_project_path(mrb_state* M, mrb_value) {
	return to_mrb(M, FileFinder(M).project_path);
}
mrb_value set_project_path(mrb_state* M, mrb_value self) {
	char* str; int str_len;
	mrb_get_args(M, "s", &str, &str_len);
	FileFinder(M).project_path.assign(str, str_len);
	return get_project_path(M, self);
}

mrb_value map_to_hash(mrb_state* M, string_map const& m) {
	mrb_value const ret = mrb_hash_new_capa(M, m.size());
	for(string_map::const_iterator i = m.begin(); i != m.end(); ++i) {
		mrb_hash_set(M, ret, to_mrb(M, i->first), to_mrb(M, i->second));
	}
	return ret;
}

mrb_value project_tree_path(mrb_state* M, mrb_value const self) {
	return to_mrb(M, get<ProjectTree>(M, self).project_path);
}
mrb_value project_tree_files(mrb_state* M, mrb_value const self) {
	return map_to_hash(M, get<ProjectTree>(M, self).files);
}
mrb_value project_tree_directories(mrb_state* M, mrb_value const self) {
	return map_to_hash(M, get<ProjectTree>(M, self).directories);
}
mrb_value project_tree_sub_members(mrb_state* M, mrb_value const self) {
	typedef FileFinder_::sub_members_type sub_members_type;
	sub_members_type const& m = get<ProjectTree>(M, self).sub_members;
	mrb_value const ret = mrb_hash_new_capa(M, m.size());
	for(sub_members_type::const_iterator i = m.begin(); i != m.end(); ++i) {
		mrb_hash_set(M, ret, to_mrb(M, i->first), map_to_hash(M, i->second));
	}
	return ret;
}

void register_project_tree(mrb_state* M) {
	static method_info const methods[] = {
		{ "project_path", &project_tree_path, MRB_ARGS_NONE() },
		{ "files", &project_tree_files, MRB_ARGS_NONE() },
		{ "directories", &project_tree_directories, MRB_ARGS_NONE() },
		{ "sub_members", &project_tree_sub_members, MRB_ARGS_NONE() },
		method_info_end };
	register_methods(M, define_class<ProjectTree>(M, "ProjectTree"), methods);
}

mrb_value fullpath(mrb_state* M, mrb_value) {
	char* str; int str_len;
	mrb_get_args(M, "s", &str, &str_len);
	return to_mrb(M, FileFinder(M).fullpath(std::string(str, str_len)));
}

mrb_value directory_members(mrb_state* M, mrb_value) {
  char* dir; int dir_len; mrb_int opt;
  mrb_get_args(M, "si", &dir, &dir_len, &opt);
  return map_to_hash(M, FileFinder(M).GetDirectoryMembers(
      std::string(dir, dir_len), FileFinder_::Mode(opt)).members);
}

mrb_value project_tree(mrb_state* M, mrb_value) {
	return clone(M, FileFinder(M).GetProjectTree());
}

mrb_value create_project_tree(mrb_state* M, mrb_value) {
	char* str; int str_len;
	mrb_get_args(M, "s", &str, &str_len);
	return clone(M, *FileFinder(M).CreateProjectTree(std::string(str, str_len)));
}

#define define_finder(name, cxx_name)									\
	mrb_value find_ ## name(mrb_state* M, mrb_value) {					\
		char* name; int name_len;										\
		mrb_get_args(M, "s", &name, &name_len);							\
		return to_mrb(M, FileFinder(M).Find ## cxx_name(std::string(name, name_len))); \
	}																	\

define_finder(sound, Sound)
define_finder(music, Music)
define_finder(movie, Movie)
define_finder(font, Font)

#undef define_finder

}

void EasyRPG::register_filefinder(mrb_state* M) {
	register_project_tree(M);

	static method_info const methods[] = {
		{ "find_image", &find_image, MRB_ARGS_REQ(2) },
		{ "update_rtp_paths", &update_rtp_paths, MRB_ARGS_NONE() },
		{ "find_default", &find_default, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(1) },
		{ "find_music", &find_music, MRB_ARGS_REQ(1) },
		{ "find_sound", &find_sound, MRB_ARGS_REQ(1) },
		{ "find_movie", &find_movie, MRB_ARGS_REQ(1) },
		{ "find_font", &find_font, MRB_ARGS_REQ(1) },
		{ "directory?", &is_directory, MRB_ARGS_REQ(1) },
		{ "exists?", &exists, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(1) },
		{ "make_path", &make_path, MRB_ARGS_REQ(1) },
		{ "project_tree", &project_tree, MRB_ARGS_NONE() },
		{ "create_project_tree", &create_project_tree, MRB_ARGS_REQ(1) },
		{ "rpg2k_project?", &is_rpg2k_project, MRB_ARGS_REQ(1) },
		{ "fullpath", &fullpath, MRB_ARGS_REQ(1) },
    { "directory_members", &directory_members, MRB_ARGS_REQ(2) },
		property_methods(project_path),
		method_info_end };
	RClass* const mod = define_module(M, "FileFinder", methods);

	// directory member listing mode
	mrb_define_const(M, mod, "ALL", mrb_fixnum_value(FileFinder_::ALL));
	mrb_define_const(M, mod, "FILES", mrb_fixnum_value(FileFinder_::FILES));
	mrb_define_const(M, mod, "DIRECTORIES", mrb_fixnum_value(FileFinder_::DIRECTORIES));
}
