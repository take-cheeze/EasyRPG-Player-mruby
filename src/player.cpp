/*
 * This file is part of EasyRPG Player.
 *
 * EasyRPG Player is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EasyRPG Player is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with EasyRPG Player. If not, see <http://www.gnu.org/licenses/>.
 */

// Headers
#include "output.h"
#include "audio.h"
#include "graphics.h"
#include "input.h"
#include "cache.h"
#include "filefinder.h"
#include "utils.h"
#include "font.h"
#include "binding.hxx"
#include "player.h"
#include "options.h"

#include <mruby/variable.h>
#include <mruby/array.h>
#include <mruby/compile.h>

namespace {

mrb_state* current_vm_ = NULL;

struct ModuleInternal {
	FontRef font;
	Cache_ cache;
	FileFinder_ filefinder;
	Graphics_ graphics;
	Input_ input;
	Output_ output;
	mrb_state* const M;

	ModuleInternal(mrb_state* vm) : font(Font::Shinonome()), M(vm) {}

	~ModuleInternal() {
		if(current_vm_ == M) { current_vm_ = NULL; }
	}
};

mrb_state* get_vm(mrb_state* M) {
	assert(current_vm_);
	return M? M : current_vm_;
}

mrb_value get_player(mrb_state* M) {
	assert(M);
	return mrb_obj_value(mrb_class_get(M, "Player"));
}

ModuleInternal& internal(mrb_state* M) {
	M = get_vm(M);
	return EasyRPG::get<ModuleInternal>(
		M, mrb_mod_cv_get(M, mrb_class_get(M, "Player"), mrb_intern_lit(M, "_module_internal")));
}

}

void Player::make_current(mrb_state* M) {
	current_vm_ = M;
}
mrb_state* Player::current_vm() { return current_vm_; }

void Player::register_player(mrb_state* M) {
	mrb_mod_cv_set(M, M->object_class, mrb_intern_lit(M, "DATABASE_NAME"), mrb_str_new_cstr(M, DATABASE_NAME));
	mrb_mod_cv_set(M, M->object_class, mrb_intern_lit(M, "TREEMAP_NAME"), mrb_str_new_cstr(M, TREEMAP_NAME));
	mrb_mod_cv_set(M, M->object_class, mrb_intern_lit(M, "SCREEN_TARGET_WIDTH"), mrb_fixnum_value(SCREEN_TARGET_WIDTH));
	mrb_mod_cv_set(M, M->object_class, mrb_intern_lit(M, "SCREEN_TARGET_HEIGHT"), mrb_fixnum_value(SCREEN_TARGET_HEIGHT));
	mrb_mod_cv_set(M, M->object_class, mrb_intern_lit(M, "DEFAULT_FPS"), mrb_fixnum_value(DEFAULT_FPS));

	RClass* const cls = EasyRPG::define_class<ModuleInternal>(M, "_ModuleInternal");

	RData* data = NULL;
	void* const ptr = EasyRPG::data_make_struct<ModuleInternal>(M, cls, data);
	assert(data);
	new(ptr) ModuleInternal(M);

	mrb_mod_cv_set(M, mrb_class_get(M, "Player"), mrb_intern_lit(M, "_module_internal"), mrb_obj_value(data));
#ifdef NDEBUG
	mrb_gv_set(M, mrb_intern_lit(M, "$DEBUG"), mrb_false_value());
#else
	mrb_gv_set(M, mrb_intern_lit(M, "$DEBUG"), mrb_true_value());
#endif
	make_current(M);
}

mrb_state* Player::create_vm() {
	mrb_state* const M = mrb_open();
	register_player(M);

	return M;
}

void Player::parse_args(int argc, char* argv[], mrb_state* M) {
	M = get_vm(M);
	mrb_value const ary = mrb_ary_new_capa(M, argc);
	for(int i = 0; i < argc; ++i) {
		mrb_ary_push(M, ary, mrb_str_new_cstr(M, argv[i]));
	}
	parse_args(ary, M);
}
void Player::parse_args(mrb_value const& args, mrb_state* M) {
	M = get_vm(M);
	mrb_funcall(M, get_player(M), "parse_args", 1, args);
}

bool Player::exit_flag(mrb_state* M) {
	M = get_vm(M);
	return mrb_test(mrb_funcall(M, get_player(M), "exit_flag", 1));
}
void Player::exit_flag(bool v, mrb_state* M) {
	M = get_vm(M);
	mrb_funcall(M, get_player(M), "exit_flag=", 1, mrb_bool_value(v));
}

bool Player::reset_flag(mrb_state* M) {
	M = get_vm(M);
	return mrb_test(mrb_funcall(M, get_player(M), "reset_flag", 0));
}
void Player::reset_flag(bool v, mrb_state* M) {
	M = get_vm(M);
	mrb_funcall(M, get_player(M), "reset_flag=", 1, mrb_bool_value(v));
}

bool Player::window_flag(mrb_state* M) {
	M = get_vm(M);
	return mrb_test(mrb_funcall(M, get_player(M), "window_flag", 0));
}

bool Player::is_rpg2k(mrb_state* M) {
	M = get_vm(M);
	return mrb_test(mrb_funcall(M, get_player(M), "rpg2k?", 0));
}
bool Player::is_rpg2k3(mrb_state* M) {
	M = get_vm(M);
	return mrb_test(mrb_funcall(M, get_player(M), "rpg2k3?", 0));
}

std::string Player::system_graphic(mrb_state* M) {
	M = get_vm(M);
	return EasyRPG::to_cxx_str(M, mrb_funcall(
		M, mrb_obj_value(mrb_class_get(M, "Game_System")), "system_name", 0));
}

#define player_function(name)						\
	void Player::name(mrb_state* M) {				\
		M = get_vm(M);								\
		mrb_funcall(M, get_player(M), #name, 0);	\
	}												\

player_function(pause)
player_function(resume)
player_function(update)

#undef player_function

void Player::run(mrb_state* M) {
	M = get_vm(M);
	mrb_load_string(M, "Player.run");
}

FontRef Font::Default(mrb_state* M) {
	return Player::current_vm()? internal(M).font : Font::Shinonome();
}

void Font::SetDefault(FontRef const& f, mrb_state* M) {
	internal(M).font = f;
}

Cache_& Cache(mrb_state* M) {
	return internal(M).cache;
}

FileFinder_& FileFinder(mrb_state* M) {
	return internal(M).filefinder;
}

Input_& Input(mrb_state* M) {
	return internal(M).input;
}

Graphics_& Graphics(mrb_state* M) {
	return internal(M).graphics;
}

Output_& Output(mrb_state* M) {
	return internal(M).output;
}
