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
#include <cassert>
#include "scene.h"
#include "graphics.h"
#include "input.h"
#include "player.h"
#include "output.h"
#include "audio.h"

SceneRef Scene::CreateNullScene() {
	return EASYRPG_MAKE_SHARED<Scene>((char const*)NULL);
}

Scene::Scene(char const* t) : type(t? t : "") {
	assert(type.empty()? t == NULL : bool(t));
}

void Scene::Start() {}
void Scene::Continue() {}
void Scene::Resume() {}
void Scene::Suspend() {}
void Scene::Update() {}

void Scene::TransitionIn() {
	Graphics().Transition(Graphics().TransitionFadeIn, 12);
}

void Scene::TransitionOut() {
	Graphics().Transition(Graphics().TransitionFadeOut, 12, true);
}
