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

#ifndef _BASEUI_H_
#define _BASEUI_H_

// Headers
#include <string>
#include <bitset>

#include "color.h"
#include "rect.h"
#include "keys.h"
#include "memory_management.h"

struct AudioInterface;

/**
 * BaseUi base abstract class.
 */
class BaseUi {
public:
	/**
	 * Virtual Destructor.
	 */
	virtual ~BaseUi() {}

	/**
	 * Resizes display.
	 *
	 * @param width display client width.
	 * @param height display client height.
	 */
	virtual void Resize(long width, long height) = 0;

	/**
	 * change fullscreen state
	 *
	 * @param f whether to enable fullscreen
	 */
	virtual void SetFullscreen(bool f) = 0;

	/**
	 * change zoom state
	 *
	 * @param z whether to enable zoom
	 */
	virtual void SetZoom(bool z) = 0;

	/**
	 * Check whether zoom mode is enabled.
	 *
	 * @return zoom state
	 */
	virtual bool IsZoomed() const = 0;

	/**
	 * Processes events queue.
	 */
	virtual void ProcessEvents() = 0;

	/**
	 * Updates video buffer.
	 */
	virtual void UpdateDisplay() = 0;

	/**
	 * Sets display title.
	 *
	 * @param title title string.
	 */
	virtual void SetTitle(const std::string &title) = 0;

	/**
	 * Displays white text in the top left corner of the screen.
	 * Used by the FPS-Display.
	 *
	 * @param text text to display.
	 */
	void DrawScreenText(const std::string &text);

	/**
	 * Displays text on the screen.
	 *
	 * @param text text to display.
	 * @param x X-coordinate where text is displayed.
	 * @param y Y-coordinate where text is displayed.
	 * @param color Text color.
	 */
	void DrawScreenText(const std::string &text, int x, int y, Color const& color = Color(255, 255, 255, 255));

	/**
	 * Sets if the cursor should be shown.
	 *
	 * @param flag cursor visibility flag.
	 * @return previous state.
	 */
	virtual void ShowCursor(bool flag) = 0;

	/**
	 * Check whether mouse cursor is visible.
	 *
	 * @return current mouse cursor visible state
	 */
	virtual bool CursorVisible() const = 0;

	/**
	 * Gets if fullscreen mode is active.
	 *
	 * @return whether fullscreen mode is active.
	 */
	virtual bool IsFullscreen() const = 0;

	/**
	 * Gets ticks in ms for time measurement.
	 *
	 * @return time in ms.
	 */
	virtual uint32_t GetTicks() const = 0;

	/**
	 * Sleeps some time.
	 *
	 * @param time_milli ms to sleep.
	 */
	virtual void Sleep(uint32_t time_milli) = 0;

	/**
	 * Returns audio instance.
	 *
	 * @return audio implementation.
	 */
	virtual AudioInterface& GetAudio() = 0;

	/**
	 * Gets client width size.
	 *
	 * @return client width size.
	 */
	virtual unsigned GetWidth() const = 0;

	/**
	 * Gets client height size.
	 *
	 * @return client height size.
	 */
	virtual unsigned GetHeight() const = 0;

	/**
	 * Gets whether mouse is hovering the display.
	 *
	 * @return whether mouse is hovering the display.
	 */
	virtual bool GetMouseFocus() const = 0;

	/**
	 * Gets mouse x coordinate.
	 *
	 * @return mouse x coordinate.
	 */
	virtual int GetMousePosX() const = 0;

	/**
	 * Gets mouse y coordinate.
	 *
	 * @return mouse y coordinate.
	 */
	virtual int GetMousePosY() const = 0;

	typedef std::bitset<Keys::KEYS_COUNT> KeyStatus;

	/**
	 * Gets vector with the all keys pressed states.
	 *
	 * @returns vector with the all keys pressed states.
	 */
	KeyStatus& GetKeyStates();

protected:
	/**
	 * Protected Constructor. Use CreateBaseUi instead.
	 */
	BaseUi();

	KeyStatus keys;
};

/** Global DisplayUi variable. */
extern EASYRPG_SHARED_PTR<BaseUi> DisplayUi;

#endif
