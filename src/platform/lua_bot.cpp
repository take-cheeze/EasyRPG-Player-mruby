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
#include "lua_bot.h"
#include "output.h"
#include "keys.h"
#include "baseui.h"
#include "player.h"

#include <cassert>

extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}


namespace {
	bool take_screenshot_per_each_key_input = true;

	int take_screenshot(lua_State* L) {
		Output::TakeScreenshot();
		return lua_yield(L, 0);
	}

	int skip(lua_State* L) {
		return lua_yield(L, 0);
	}

	template<Keys::InputKey Key>
	int press(lua_State* L) {
		DisplayUi->GetKeyStates()[Key] = true;

		if(take_screenshot_per_each_key_input) {
			Output::TakeScreenshot();
		}

		return lua_yield(L, 0);
	}

	int quit(lua_State* L) {
		Player().exit_flag = true;
		return lua_yield(L, 0);
	}

} // anonymous namespace

void LuaBot::register_vm(lua_State* const L) {
	luaL_openlibs(L);

	lua_register(L, "take_screenshot", &take_screenshot);
	lua_register(L, "skip", &skip);
	lua_register(L, "quit", &quit);

	// keys
	lua_register(L, "up", &press<Keys::UP>);
	lua_register(L, "down", &press<Keys::DOWN>);
	lua_register(L, "left", &press<Keys::LEFT>);
	lua_register(L, "right", &press<Keys::RIGHT>);
	lua_register(L, "enter", &press<Keys::RETURN>);
	lua_register(L, "cancel", &press<Keys::ESCAPE>);
}

LuaBot::LuaBot(std::string const& script)
	: script_(script), executer_(NULL)
{
	vm_.reset(luaL_newstate(), &lua_close);
	assert(vm_);
	lua_State* const L = vm_.get();

	LuaBot::register_vm(L);

	executer_ = lua_newthread(L);
	assert(executer_);
	assert(lua_type(L, -1) == LUA_TTHREAD);

	switch(luaL_loadstring(executer_, script_.c_str())) {
	case 0: // LUA_OK
		break;

	case LUA_ERRSYNTAX:
	case LUA_ERRMEM:
	default: // case LUA_ERRGCMM:
		assert(lua_isstring(executer_, -1));
		Output::Debug("Script loading error: %s", lua_tostring(executer_, -1));

		lua_pop(executer_, 1);
		finish();

		break;
	}
}

void LuaBot::resume() {
	assert(!is_finished());

	lua_State* const L = vm_.get();
	assert(L);
	assert(lua_type(L, -1) == LUA_TTHREAD);

#if LUA_VERSION_NUM >= 502
	switch(lua_resume(executer_, L, 0)) {
#else
	switch(lua_resume(executer_, 0)) {
#endif
	case 0: // LUA_OK
		Output::Debug("Script ended. Quiting");
		finish();
	case LUA_YIELD:
		break;

	default:
		assert(lua_isstring(L, -1));
		Output::Debug("Error while executing script: %s", lua_tostring(L, -1));

		lua_pop(L, 1);
		finish();

		break;
	}
}
