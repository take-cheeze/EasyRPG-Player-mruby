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
#include "keys.h"
#include "input.h"

void Input_::InitButtonsDesktop() {
	buttons[UP].push_back(Keys::UP);
	buttons[UP].push_back(Keys::K);
	buttons[UP].push_back(Keys::KP8);
	buttons[DOWN].push_back(Keys::DOWN);
	buttons[DOWN].push_back(Keys::J);
	buttons[DOWN].push_back(Keys::KP2);
	buttons[LEFT].push_back(Keys::LEFT);
	buttons[LEFT].push_back(Keys::H);
	buttons[LEFT].push_back(Keys::KP4);
	buttons[RIGHT].push_back(Keys::RIGHT);
	buttons[RIGHT].push_back(Keys::L);
	buttons[RIGHT].push_back(Keys::KP6);
	buttons[DECISION].push_back(Keys::Z);
	buttons[DECISION].push_back(Keys::SPACE);
	buttons[DECISION].push_back(Keys::RETURN);
	buttons[CANCEL].push_back(Keys::X);
	buttons[CANCEL].push_back(Keys::C);
	buttons[CANCEL].push_back(Keys::V);
	buttons[CANCEL].push_back(Keys::B);
	buttons[CANCEL].push_back(Keys::N);
	buttons[CANCEL].push_back(Keys::ESCAPE);
	buttons[SHIFT].push_back(Keys::LSHIFT);
	buttons[SHIFT].push_back(Keys::RSHIFT);
	buttons[N0].push_back(Keys::N0);
	buttons[N1].push_back(Keys::N1);
	buttons[N2].push_back(Keys::N2);
	buttons[N3].push_back(Keys::N3);
	buttons[N4].push_back(Keys::N4);
	buttons[N5].push_back(Keys::N5);
	buttons[N6].push_back(Keys::N6);
	buttons[N7].push_back(Keys::N7);
	buttons[N8].push_back(Keys::N8);
	buttons[N9].push_back(Keys::N9);
	buttons[PLUS].push_back(Keys::ADD);
	buttons[MINUS].push_back(Keys::SUBTRACT);
	buttons[MULTIPLY].push_back(Keys::MULTIPLY);
	buttons[DIVIDE].push_back(Keys::DIVIDE);
	buttons[PERIOD].push_back(Keys::PERIOD);
	buttons[DEBUG_MENU].push_back(Keys::F9);
	buttons[DEBUG_THROUGH].push_back(Keys::LCTRL);
	buttons[DEBUG_THROUGH].push_back(Keys::RCTRL);
	buttons[TAKE_SCREENSHOT].push_back(Keys::F10);
	buttons[TOGGLE_FPS].push_back(Keys::F2);
	buttons[LOG_VIEWER].push_back(Keys::F8);

	buttons[DECISION].push_back(Keys::MOUSE_LEFT);
	buttons[CANCEL].push_back(Keys::MOUSE_RIGHT);
	buttons[SHIFT].push_back(Keys::MOUSE_MIDDLE);
}

void Input_::InitButtons() {
	InitButtonsDesktop();

	dir_buttons[2].push_back(DOWN);
	dir_buttons[4].push_back(LEFT);
	dir_buttons[6].push_back(RIGHT);
	dir_buttons[8].push_back(UP);
}
