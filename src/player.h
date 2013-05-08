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

#ifndef _PLAYER_H_
#define _PLAYER_H_

// Headers
#include <boost/noncopyable.hpp>
#include <boost/scoped_ptr.hpp>
#include "memory_management.h"

struct Player_;

Player_& Player();

typedef EASYRPG_SHARED_PTR<Player_> PlayerRef;
PlayerRef CreatePlayer();

/**
 * Player namespace.
 */
struct Player_ : boost::noncopyable {
	enum EngineType {
		EngineRpg2k,
		EngineRpg2k3
	};

	/**
	 * Parse command line arguments
	*/
	void ParseArgs(int argc, char *argv[]);

	/**
	 * Runs the game engine.
	*/
	void Run();

	/**
	 * Pauses the game engine.
	*/
	void Pause();

	/**
	 * Resumes the game engine.
	*/
	void Resume();

	/**
	 * Updates EasyRPG Player.
	 */
	void Update();

	/** Exit flag, if true will exit application on next Player::Update. */
	bool exit_flag;

	/** Reset flag, if true will restart game on next Player::Update. */
	bool reset_flag;

	/** Debug flag, if true will run game in debug mode. */
	bool debug_flag;

	/** Hide Title flag, if true title scene will run without image and music. */
	bool hide_title_flag;

	/** Window flag, if true will run in window mode instead of full screen. */
	bool window_flag;

	/** Battle Test flag, if true will run battle test. */
	bool battle_test_flag;

	/** Battle Test Troop ID to fight with if battle test is run. */
	int battle_test_troop_id;

	/** Currently interpreted engine. */
	EngineType engine;

	/** make this player current */
	void MakeCurrent();

	struct Internal;
	boost::scoped_ptr<Internal> const internal;

  private:
	friend PlayerRef CreatePlayer();

	Player_();

	EASYRPG_WEAK_PTR<Player_> ref_;
};

#endif
