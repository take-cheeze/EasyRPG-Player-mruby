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

#ifndef _SCENE_H_
#define _SCENE_H_

// Headers
#include "system.h"
#include <vector>
#include <string>

#include <boost/noncopyable.hpp>

class Scene;
typedef EASYRPG_SHARED_PTR<Scene> SceneRef;

/**
 * Scene virtual class.
 */
class Scene : boost::noncopyable {
public:
	static SceneRef CreateNullScene();

	/**
	 * Constructor.
	 */
	Scene(char const* name);

	/**
	 * Destructor.
	 */
	virtual ~Scene() {};

	/**
	 * Scene entry point.
	 * The Scene Main-Function manages a stack and always
	 * executes the scene that is currently on the top of
	 * the stack.
	 */
	virtual void MainFunction();

	/**
	 * Start processing.
	 * This function is executed while the screen is faded
	 * out. All objects needed for the scene should be
	 * created here.
	 */
	virtual void Start();

	/**
	 * Continue processing.
	 * This function is executed when returning from a
	 * nested scene (instead of Start).
	 */
	virtual void Continue();

	/**
	 * Resume processing.
	 * This function is executed after the fade in,
	 * either when starting the scene or when returning
	 * from a nested scene
	 */
	virtual void Resume();

	/**
	 * Suspend processing.
	 * This function is executed before the fade out for
	 * the scene change, either when terminating the scene
	 * or switching to a nested scene
	 */
	virtual void Suspend();

	/**
	 * Does the transition upon starting or resuming
	 * the scene
	 */
	virtual void TransitionIn();

	/**
	 * Does the transition upon ending or suspending
	 * the scene
	 */
	virtual void TransitionOut();

	/**
	 * Called every frame.
	 * The scene should redraw all elements.
	 */
	virtual void Update();

	/**
	 * Pushes a new scene on the scene execution stack.
	 *
	 * @param new_scene new scene.
	 * @param pop_stack_top if the scene that is currently
	 *                      on the top should be popped.
	 */
	static void Push(SceneRef const& new_scene, bool pop_stack_top = false);

	/**
	 * Removes the scene that is on the top of the stack.
	 */
	static void Pop();

	/**
	 * Removes scenes from the stack, until a specific one
	 * is reached.
	 *
	 * @param type type of the scene that is searched.
	 */
	static void PopUntil(std::string const& type);

	/**
	 * Finds the topmost scene of a specific type on the stack.
	 *
	 * @param type type of the scene that is searched.
	 * @return the scene found, or NULL if no such scene exists.
	 */
	static SceneRef Find(std::string const& type);

	/**
	 * Scene type.
	 * if empty it's a null scene
	 */
	std::string const type;
};

#endif
