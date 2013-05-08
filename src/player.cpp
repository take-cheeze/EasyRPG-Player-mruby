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
#include "player.h"
#include "system.h"
#include "output.h"
#include "audio.h"
#include "graphics.h"
#include "input.h"
#include "cache.h"
#include "filefinder.h"
#include "main_data.h"
#include "scene_logo.h"
#include "scene_title.h"
#include "scene_battle.h"
#include "utils.h"
#include "baseui.h"

#include <algorithm>
#include <set>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <ciso646>

struct Player_::Internal {
	Cache_ cache;
	FileFinder_ filefinder;
	Graphics_ graphics;
	Input_ input;
};

static EASYRPG_WEAK_PTR<Player_> current_player_;

Cache_& Cache() {
	return Player().internal->cache;
}

FileFinder_& FileFinder() {
	return Player().internal->filefinder;
}

Input_& Input() {
	return Player().internal->input;
}

Graphics_& Graphics() {
	return Player().internal->graphics;
}

Player_& Player() {
	assert(not current_player_.expired());
	return *current_player_.lock();
}

PlayerRef CreatePlayer() {
	PlayerRef const ret(new Player_());
	ret->ref_ = ret;
	ret->MakeCurrent();
	ret->internal->filefinder.UpdateRtpPaths();
	return ret;
}

void Player_::MakeCurrent() {
	assert(not ref_.expired());
	current_player_ = ref_;
}

Player_::Player_()
		:  exit_flag(false)
		, reset_flag(false)
		, debug_flag(false)
		, hide_title_flag(false)
		, window_flag(false)
		, battle_test_flag(false)
		, battle_test_troop_id(0)
		, engine(EngineRpg2k)
		, internal(new Internal())
{
}

static bool arg_exists(std::vector<std::string>& lst, std::string const& arg) {
	std::vector<std::string>::iterator const i = std::find(lst.begin(), lst.end(), arg);
	return (i == lst.end())? false : (lst.erase(i), true);
}

void Player_::ParseArgs(int argc, char* argv[]) {
	if((argc > 1) && Utils::LowerCase(argv[1]) == "battletest") {
		battle_test_flag = true;
		battle_test_troop_id = (argc > 4)? atoi(argv[4]) : 0;
	} else {
		std::vector<std::string> const args(argv + 1, argv + argc);
		std::vector<std::string> lowered_args(args.size());
		std::transform(args.begin(), args.end(), lowered_args.begin(), &Utils::LowerCase);

		window_flag = arg_exists(lowered_args, "window");
		debug_flag = arg_exists(lowered_args, "testplay");
		hide_title_flag = arg_exists(lowered_args, "hidetitle");

		if(not lowered_args.empty()) {
			Output::Debug("Unknown arguments passed.");
		}
	}

#ifndef NDEBUG
	debug_flag = true;
	window_flag = true; // Debug Build needs no fullscreen
#endif
}

void Player_::Run() {
	assert(DisplayUi);

	Scene::Push(EASYRPG_MAKE_SHARED<Scene>());
	Scene::Push(EASYRPG_SHARED_PTR<Scene>
				(debug_flag?
				 static_cast<Scene*>(new Scene_Title()) :
				 static_cast<Scene*>(new Scene_Logo())));

	reset_flag = false;

	// Reset frames before starting
	Graphics().FrameReset();

	// Main loop
	while (Scene::instance->type != Scene::Null) {
		Scene::instance->MainFunction();
		for (size_t i = 0; i < Scene::old_instances.size(); ++i) {
			Graphics().Pop();
		}
		Scene::old_instances.clear();
	}
}

void Player_::Pause() {
	Audio().BGM_Pause();
}

void Player_::Resume() {
	Input().ResetKeys();
	Audio().BGM_Resume();
	Graphics().FrameReset();
}

void Player_::Update() {
	if (Input().IsTriggered(Input_::TOGGLE_FPS)) {
		Graphics().fps_on_screen = !Graphics().fps_on_screen;
	}
	if (Input().IsTriggered(Input_::TAKE_SCREENSHOT)) {
		Output::TakeScreenshot();
	}

	DisplayUi->ProcessEvents();

	if (exit_flag) {
		Scene::PopUntil(Scene::Null);
	} else if (reset_flag) {
		reset_flag = false;
		Scene::PopUntil(Scene::Title);
	}
}
