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

#ifndef _SDL_UI_H_
#define _SDL_UI_H_

// Headers
#include "baseui.h"

#include <boost/scoped_ptr.hpp>
#include <SDL.h>

struct AudioInterface;

/**
 * SdlUi class.
 */
class SdlUi : public BaseUi {
public:
	/**
	 * Constructor.
	 *
	 * @param width window client width.
	 * @param height window client height.
	 * @param title window title.
	 * @param fullscreen start in fullscreen flag.
	 */
	SdlUi(unsigned width, unsigned height, const std::string& title, bool fullscreen);

	/**
	 * Destructor.
	 */
	~SdlUi();

	/**
	 * Inherited from BaseUi.
	 */
	/** @{ */

	void Resize(long width, long height);
	bool IsFullscreen() const;
	void SetFullscreen(bool f);
	bool IsZoomed() const;
	void SetZoom(bool z);
	void UpdateDisplay();
	void SetTitle(const std::string &title);

	void ShowCursor(bool flag);
	bool CursorVisible() const;

	void ProcessEvents();

	unsigned GetWidth() const;
	unsigned GetHeight() const;

	bool GetMouseFocus() const;
	int GetMousePosX() const;
	int GetMousePosY() const;

	uint32_t GetTicks() const;
	void Sleep(uint32_t time_milli);

	AudioInterface& GetAudio();

	/** @} */

	/** Get display surface. */
	BitmapRef GetDisplaySurface();

private:
	/**
	 * Processes a SDL Event.
	 */
	/** @{ */

	void ProcessEvent(SDL_Event &sdl_event);

	void ProcessActiveEvent(SDL_Event &evnt);
	void ProcessKeyDownEvent(SDL_Event &evnt);
	void ProcessKeyUpEvent(SDL_Event &evnt);
	void ProcessMouseMotionEvent(SDL_Event &evnt);
	void ProcessMouseButtonEvent(SDL_Event &evnt);

	/** @} */

	/**
	 * Sets app icon.
	 */
	void SetAppIcon();

	/**
	 * Resets keys states.
	 */
	void ResetKeys();

	EASYRPG_SHARED_PTR<SDL_Texture> screen_;
	EASYRPG_SHARED_PTR<SDL_Window> window_;
	EASYRPG_SHARED_PTR<SDL_Renderer> renderer_;

	bool is_full_screen_, is_zoomed_;

	bool mouse_focus_;
	int mouse_x_, mouse_y_;

	unsigned initial_width_, initial_height_;

	boost::scoped_ptr<AudioInterface> audio_;
};

#endif
