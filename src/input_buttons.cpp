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

#if defined(USE_MOUSE) && defined(SUPPORT_MOUSE)
	buttons[DECISION].push_back(Keys::MOUSE_LEFT);
	buttons[CANCEL].push_back(Keys::MOUSE_RIGHT);
	buttons[SHIFT].push_back(Keys::MOUSE_MIDDLE);
#endif

#if defined(USE_JOYSTICK) && defined(SUPPORT_JOYSTICK)
	// FIXME: Random joystick keys mapping, better to read joystick configuration from .ini
	buttons[UP].push_back(Keys::JOY_8);
	buttons[DOWN].push_back(Keys::JOY_2);
	buttons[LEFT].push_back(Keys::JOY_4);
	buttons[RIGHT].push_back(Keys::JOY_6);
	buttons[DECISION].push_back(Keys::JOY_1);
	buttons[CANCEL].push_back(Keys::JOY_3);
	buttons[SHIFT].push_back(Keys::JOY_5);
	buttons[N0].push_back(Keys::JOY_10);
	buttons[N1].push_back(Keys::JOY_11);
	buttons[N2].push_back(Keys::JOY_12);
	buttons[N3].push_back(Keys::JOY_13);
	buttons[N4].push_back(Keys::JOY_14);
	buttons[N5].push_back(Keys::JOY_15);
	buttons[N6].push_back(Keys::JOY_16);
	buttons[N7].push_back(Keys::JOY_17);
	buttons[N8].push_back(Keys::JOY_18);
	buttons[N9].push_back(Keys::JOY_19);
	buttons[PLUS].push_back(Keys::JOY_20);
	buttons[MINUS].push_back(Keys::JOY_21);
	buttons[MULTIPLY].push_back(Keys::JOY_22);
	buttons[DIVIDE].push_back(Keys::JOY_23);
	buttons[PERIOD].push_back(Keys::JOY_24);
	buttons[DEBUG_MENU].push_back(Keys::JOY_7);
	buttons[DEBUG_THROUGH].push_back(Keys::JOY_9);
#endif

#if defined(USE_JOYSTICK_HAT)  && defined(SUPPORT_JOYSTICK_HAT)
	buttons[DOWN].push_back(Keys::JOY_HAT_DOWN);
	buttons[LEFT].push_back(Keys::JOY_HAT_LEFT);
	buttons[RIGHT].push_back(Keys::JOY_HAT_RIGHT);
	buttons[UP].push_back(Keys::JOY_HAT_UP);
#endif

#if defined(USE_JOYSTICK_AXIS)  && defined(SUPPORT_JOYSTICK_AXIS)
	buttons[LEFT].push_back(Keys::JOY_AXIS_X_LEFT);
	buttons[RIGHT].push_back(Keys::JOY_AXIS_X_RIGHT);
	buttons[DOWN].push_back(Keys::JOY_AXIS_Y_DOWN);
	buttons[UP].push_back(Keys::JOY_AXIS_Y_UP);
#endif
}

void Input_::InitButtonsDingoo() {
	buttons[UP].push_back(Keys::UP);
	buttons[DOWN].push_back(Keys::DOWN);
	buttons[LEFT].push_back(Keys::LEFT);
	buttons[RIGHT].push_back(Keys::RIGHT);
	buttons[DECISION].push_back(Keys::RETURN); //START
	buttons[DECISION].push_back(Keys::LCTRL); //A
	buttons[CANCEL].push_back(Keys::ESCAPE); //SELECT
	buttons[CANCEL].push_back(Keys::LALT); //B
	buttons[N1].push_back(Keys::LSHIFT);//Y
	buttons[N2].push_back(Keys::SPACE);//X

	buttons[DEBUG_MENU].push_back(Keys::TAB);//L
	buttons[DEBUG_THROUGH].push_back(Keys::BACKSPACE);//R
}

void Input_::InitButtonsGekko() {
	// Remote
	buttons[TOGGLE_FPS].push_back(Keys::JOY_0); // A
	//buttons[N1].push_back(Keys::JOY_0); // A
	buttons[N2].push_back(Keys::JOY_1); // B
	buttons[CANCEL].push_back(Keys::JOY_2); // 1
	buttons[DECISION].push_back(Keys::JOY_3); // 2
	buttons[MINUS].push_back(Keys::JOY_4); // -
	buttons[PLUS].push_back(Keys::JOY_5); // +
	buttons[CANCEL].push_back(Keys::JOY_6); // Home

	// Nunchuck
	buttons[DECISION].push_back(Keys::JOY_7); // Z
	buttons[CANCEL].push_back(Keys::JOY_8); // C

	// Classic Controller
	buttons[DECISION].push_back(Keys::JOY_9); // A
	buttons[CANCEL].push_back(Keys::JOY_10); // B
	buttons[N1].push_back(Keys::JOY_11); // X
	buttons[N2].push_back(Keys::JOY_12); // Y
	buttons[SHIFT].push_back(Keys::JOY_13); // L
	buttons[DEBUG_THROUGH].push_back(Keys::JOY_14); // R
	buttons[MULTIPLY].push_back(Keys::JOY_15); // Zl
	buttons[DIVIDE].push_back(Keys::JOY_16); // Zr
	buttons[MINUS].push_back(Keys::JOY_17); // -
	buttons[PLUS].push_back(Keys::JOY_18); // +
	buttons[CANCEL].push_back(Keys::JOY_19); // Home

	buttons[DOWN].push_back(Keys::JOY_HAT_DOWN);
	buttons[LEFT].push_back(Keys::JOY_HAT_LEFT);
	buttons[RIGHT].push_back(Keys::JOY_HAT_RIGHT);
	buttons[UP].push_back(Keys::JOY_HAT_UP);

	buttons[LEFT].push_back(Keys::JOY_AXIS_X_LEFT);
	buttons[RIGHT].push_back(Keys::JOY_AXIS_X_RIGHT);
	buttons[DOWN].push_back(Keys::JOY_AXIS_Y_DOWN);
	buttons[UP].push_back(Keys::JOY_AXIS_Y_UP);
}

void Input_::InitButtonsCaanoo() {
	buttons[DEBUG_MENU].push_back(Keys::JOY_4); // L
	buttons[DEBUG_THROUGH].push_back(Keys::JOY_5); // R
	buttons[N1].push_back(Keys::JOY_3); // Y
	buttons[CANCEL].push_back(Keys::JOY_2); // B
	buttons[N2].push_back(Keys::JOY_1); // X
	buttons[DECISION].push_back(Keys::JOY_0); // A
	buttons[CANCEL].push_back(Keys::JOY_9); // HELP1
	buttons[DECISION].push_back(Keys::JOY_8); // HELP2
}

void Input_::InitButtonsGP2XWIZ() {
	buttons[DEBUG_MENU].push_back(Keys::JOY_10); // L
	buttons[DEBUG_THROUGH].push_back(Keys::JOY_11); // R
	buttons[N1].push_back(Keys::JOY_15); // Y
	buttons[CANCEL].push_back(Keys::JOY_13); // B
	buttons[N2].push_back(Keys::JOY_14); // X
	buttons[DECISION].push_back(Keys::JOY_12); // A
	buttons[CANCEL].push_back(Keys::JOY_8); // SELECT
	buttons[DECISION].push_back(Keys::JOY_9); // MENU
}

void Input_::InitButtonsGPH() {
#if defined(USE_CAANOO)
	InitButtonsCaanoo();
#elif defined(USE_GP2XWIZ)
	InitButtonsGP2XWIZ();
#elif defined(GPH)
#  error "unknown gph hardware"
#endif

	buttons[LEFT].push_back(Keys::JOY_AXIS_X_LEFT);
	buttons[RIGHT].push_back(Keys::JOY_AXIS_X_RIGHT);
	buttons[DOWN].push_back(Keys::JOY_AXIS_Y_DOWN);
	buttons[UP].push_back(Keys::JOY_AXIS_Y_UP);
}

void Input_::InitButtonsPSP() {
	buttons[DECISION].push_back(Keys::JOY_1); // Circle
	buttons[DECISION].push_back(Keys::JOY_2); // Cross
	buttons[CANCEL].push_back(Keys::JOY_3); // Square

	buttons[TOGGLE_FPS].push_back(Keys::JOY_0); // Triangle

	buttons[N1].push_back(Keys::JOY_4); // Left trigger
	buttons[N2].push_back(Keys::JOY_5); // Right trigger

	buttons[DOWN].push_back(Keys::JOY_6); // Down
	buttons[LEFT].push_back(Keys::JOY_7); // Left
	buttons[UP].push_back(Keys::JOY_8); // Up
	buttons[RIGHT].push_back(Keys::JOY_9); // Right
}

void Input_::InitButtons() {
#if defined(PSP)
	InitButtonsPSP();
#elif defined(DINGOO)
	InitButtonsDingoo();
#elif defined(GEKKO)
	InitButtonsGekko();
#elif defined(GPH)
	InitButtonsGPH();
#else
	InitButtonsDesktop();
#endif

	dir_buttons[2].push_back(DOWN);
	dir_buttons[4].push_back(LEFT);
	dir_buttons[6].push_back(RIGHT);
	dir_buttons[8].push_back(UP);
}
