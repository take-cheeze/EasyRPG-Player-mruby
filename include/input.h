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

#ifndef _EASY_INPUT_H_
#define _EASY_INPUT_H_

// Headers
#include <vector>
#include <bitset>
#include <array>

#include <boost/noncopyable.hpp>

/**
 * Input namespace.
 * Input works with Button states. Buttons are
 * representations of one or more keys or actions (like
 * keyboard keys, mouse buttons, joystick axis). This way
 * buttons are platform and device independent, while the
 * assigned keys can vary by the system.
 */
struct Input_ : boost::noncopyable {
	enum Button {
		UP,
		DOWN,
		LEFT,
		RIGHT,
		DECISION,
		CANCEL,
		SHIFT,
		N0,
		N1,
		N2,
		N3,
		N4,
		N5,
		N6,
		N7,
		N8,
		N9,
		PLUS,
		MINUS,
		MULTIPLY,
		DIVIDE,
		PERIOD,
		DEBUG_MENU,
		DEBUG_THROUGH,
		TOGGLE_FPS,
		TAKE_SCREENSHOT,
		LOG_VIEWER,
		A, B, C, X, Y, Z, L, R, CTRL, ALT, F5, F6, F7, F8, F9,
		BUTTON_COUNT
	};

	/**
	 * Initializes Input.
	 */
	Input_();

	/**
	 * Updates Input state.
	 */
	void Update();

	/**
	 * Resets all button states.
	 */
	void ResetKeys();

	/**
	 * Gets if a button is being pressed.
	 *
	 * @param button button ID.
	 * @return whether the button is being pressed.
	 */
	bool IsPressed(Button button);

	/**
	 * Gets if a button is starting to being pressed.
	 *
	 * @param button button ID.
	 * @return whether the button is being triggered.
	 */
	bool IsTriggered(Button button);

	/**
	 * Gets if a button is being repeated. A button is being
	 * repeated while it is maintained pressed and a
	 * certain amount of frames has passed after last
	 * repetition.
	 *
	 * @param button button ID.
	 * @return whether the button is being repeated.
	 */
	bool IsRepeated(Button button);

	/**
	 * Gets if a button is being released.
	 *
	 * @param button button ID.
	 * @return whether the button is being released.
	 */
	bool IsReleased(Button button);

	/**
	 * Gets if any button is being pressed.
	 *
	 * @return whether any button is being pressed.
	 */
	bool IsAnyPressed();

	/**
	 * Gets if any button is being triggered.
	 *
	 * @return whether any button is being triggered.
	 */
	bool IsAnyTriggered();

	/**
	 * Gets if any button is being repeated.
	 *
	 * @return whether any button is being repeated.
	 */
	bool IsAnyRepeated();

	/**
	 * Gets if any button is being released.
	 *
	 * @return whether any button is being released.
	 */
	bool IsAnyReleased();

	/**
	 * Gets all buttons being pressed.
	 *
	 * @return a vector with the buttons IDs.
	 */
	std::vector<Button> GetAllPressed();

	/**
	 * Gets all buttons being triggered.
	 *
	 * @return a vector with the buttons IDs.
	 */
	std::vector<Button> GetAllTriggered();

	/**
	 * Gets all buttons being repeated.
	 *
	 * @return a vector with the buttons IDs.
	 */
	std::vector<Button> GetAllRepeated();

	/**
	 * Gets all buttons being released.
	 *
	 * @return a vector with the buttons IDs.
	 */
	std::vector<Button> GetAllReleased();

	/** Buttons press time (in frames). */
	std::array<int, BUTTON_COUNT> press_time;

	/** Buttons trigger state. */
	std::bitset<BUTTON_COUNT> triggered;

	/** Buttons trigger state. */
	std::bitset<BUTTON_COUNT> repeated;

	/** Buttons trigger state. */
	std::bitset<BUTTON_COUNT> released;

	/** Horizontal and vertical directions state. */
	int dir4;

	/** All cardinal directions state. */
	int dir8;

	/**
	 * Start repeat time (in frames) a key has
	 * to be maintained pressed before being
	 * repeated for fist time.
	 */
	int start_repeat_time;

	/**
	 * Repeat time (in frames) a key has to be
	 * maintained pressed after the start repeat time
	 * has passed for being repeated again.
	 */
	int repeat_time;

	bool IsWaitingInput();
	void WaitInput(bool val);

	/** Buttons list of equivalent keys. */
	static std::array<std::vector<int>, BUTTON_COUNT> buttons;

	/** Direction buttons list of equivalent buttons. */
	static std::array<std::vector<int>, 10> dir_buttons;

  private:
	bool wait_input;

	/**
	 * Initializes input buttons to their mappings.
	 */
	void InitButtons();

	void InitButtonsPSP();
	void InitButtonsGekko();
	void InitButtonsDingoo();
	void InitButtonsDesktop();

	void InitButtonsGPH();
	void InitButtonsCaanoo();
	void InitButtonsGP2XWIZ();
};

#include <mruby.h>

Input_& Input(mrb_state* M = NULL);

#endif
