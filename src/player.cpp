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
#include "scene_project_finder.h"
#include "scene_log_viewer.h"
#include "utils.h"
#include "baseui.h"
#include "font.h"

#include <algorithm>
#include <set>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <ciso646>

#include <boost/bind.hpp>
#include <boost/format.hpp>

namespace {

enum PushPopOperation {
	SceneNop,
	ScenePushed,
	ScenePopped
};

bool SceneFinder(SceneRef const& r, std::string const& t) {
	return r->type == t;
}

}

struct Player_::Internal {
	FontRef font;
	Cache_ cache;
	FileFinder_ filefinder;
	Graphics_ graphics;
	Input_ input;
	Output_ output;

	struct {
		/** Current scene. */
		SceneRef instance;

		/** Old scenes, temporary save for deleting. */
		std::vector<SceneRef> old_instances;

		std::vector<SceneRef> instances;

		PushPopOperation push_pop_operation;
	} scene;

	Internal() : font(Font::Shinonome()) {
		scene.push_pop_operation = SceneNop;
	}
};

void Scene::PopUntil(std::string const& type) {
	int count = 0;

	for (int i = (int)Player().internal->scene.instances.size() - 1 ; i >= 0; --i) {
		if (Player().internal->scene.instances[i]->type == type) {
			for (i = 0; i < count; ++i) {
				Player().internal->scene.old_instances.push_back(Player().internal->scene.instances.back());
				Player().internal->scene.instances.pop_back();
			}
			Player().internal->scene.instance = Player().internal->scene.instances.back();
			Player().internal->scene.push_pop_operation = ScenePopped;
			return;
		}
		++count;
	}

	Output().Warning(boost::format("The requested scene %s was not on the stack") % type);
}

EASYRPG_SHARED_PTR<Scene> Scene::Find(std::string const& type) {
	std::vector<SceneRef> const& instances = Player().internal->scene.instances;
	std::vector<SceneRef>::const_reverse_iterator it =
			std::find_if(instances.rbegin(), instances.rend(),
						 boost::bind(SceneFinder, _1, type));
	return it != instances.rend()? *it : EASYRPG_SHARED_PTR<Scene>();
}

void Scene::Push(SceneRef const& new_scene, bool pop_stack_top) {
	if (pop_stack_top) {
		Player().internal->scene.old_instances.push_back(
			Player().internal->scene.instances.back());
		Player().internal->scene.instances.pop_back();
	}

	Player().internal->scene.instances.push_back(new_scene);
	Player().internal->scene.instance = new_scene;

	Player().internal->scene.push_pop_operation = ScenePushed;

	/*Output::Debug("Scene Stack after Push:");
	for (size_t i = 0; i < instances.size(); ++i) {
		Output::Debug(scene_names[instances[i]->type]);
	}*/
}

void Scene::Pop() {
	Player().internal->scene.old_instances.push_back(
		Player().internal->scene.instances.back());
	Player().internal->scene.instances.pop_back();

	if (Player().internal->scene.instances.size() == 0) {
		Push(Scene::CreateNullScene()); // Null-scene
	} else {
		Player().internal->scene.instance = Player().internal->scene.instances.back();
	}

	Player().internal->scene.push_pop_operation = ScenePopped;

	/*Output::Debug("Scene Stack after Pop:");
	for (size_t i = 0; i < instances.size(); ++i) {
		Output::Debug(scene_names[instances[i]->type]);
	}*/
}

void Scene::MainFunction() {
	switch(Player().internal->scene.push_pop_operation) {
	case ScenePushed:
		Start();
		break;
	case ScenePopped:
		Continue();
		break;
	case SceneNop: break;
	default: assert(false);
	}

	Player().internal->scene.push_pop_operation = SceneNop;

	TransitionIn();
	Resume();

	// Scene loop
	while (Player().internal->scene.instance.get() == this) {
		Player().Update();
		Graphics().Update();
		Audio().Update();
		Input().Update();
		Update();
	}

	assert(Player().internal->scene.instance == Player().internal->scene.instances.back() &&
		   "Don't set Scene::instance directly, use Push instead!");

	Graphics().Update();

	Suspend();
	TransitionOut();

	switch (Player().internal->scene.push_pop_operation) {
	case ScenePushed:
		Graphics().Push();
		break;
	// Graphics().Pop done in Player Loop
	case ScenePopped:
	case SceneNop:
		break;
	default: assert(false);
	}
}

static EASYRPG_WEAK_PTR<Player_> current_player_;

FontRef Font::Default() {
	return current_player_.lock()? Player().internal->font : Font::Shinonome();
}

void Font::SetDefault(FontRef const& f) {
	Player().internal->font = f;
}

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

Output_& Output() {
	return Player().internal->output;
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
			Output().Debug("Unknown arguments passed.");
		}
	}

#ifndef NDEBUG
	debug_flag = true;
	window_flag = true; // Debug Build needs no fullscreen
#endif
}

void Player_::Run() {
	assert(DisplayUi);

	Scene::Push(Scene::CreateNullScene());
	Scene::Push(SceneRef
				(not FileFinder().IsRPG2kProject(FileFinder().GetProjectTree())
				 ? static_cast<Scene*>(new Scene_ProjectFinder()):
				 debug_flag
				 ? static_cast<Scene*>(new Scene_Title()):
				 static_cast<Scene*>(new Scene_Logo())));

	reset_flag = false;

	// Reset frames before starting
	Graphics().FrameReset();

	// Main loop
	while (not internal->scene.instance->type.empty()) {
		internal->scene.instance->MainFunction();
		for (size_t i = 0; i < internal->scene.old_instances.size(); ++i) {
			Graphics().Pop();
		}
		internal->scene.old_instances.clear();
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
		// use debug output for log viewer
		// Output().TakeScreenshot();
		Output().Debug("Screenshot request from user.");
	}
	if (Input().IsTriggered(Input_::LOG_VIEWER)) {
		Scene::Find("Log Viewer")
				? Scene::Pop()
				: Scene::Push(EASYRPG_MAKE_SHARED<Scene_LogViewer>());
	}

	DisplayUi->ProcessEvents();
	Output().Update();

	if (exit_flag) {
		Scene::PopUntil(std::string());
	} else if (reset_flag) {
		reset_flag = false;
		Scene::PopUntil("Title");
	}
}
