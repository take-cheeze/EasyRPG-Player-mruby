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
#include "baseui.h"
#include "system.h"
#include "bitmap.h"

#ifdef USE_SDL
#include "sdl_ui.h"
#endif

EASYRPG_SHARED_PTR<BaseUi> DisplayUi;

BaseUi::BaseUi()
	: mouse_focus(false)
	, mouse_x(0)
	, mouse_y(0)
	, cursor_visible(false)
{
	keys.reset();
}

BaseUi::KeyStatus& BaseUi::GetKeyStates() {
	return keys;
}

long BaseUi::GetWidth() const {
	return current_display_mode.width;
}

long BaseUi::GetHeight() const {
	return current_display_mode.height;
}

bool BaseUi::GetMouseFocus() const {
	return mouse_focus;
}

int BaseUi::GetMousePosX() const {
	return mouse_x;
}

int BaseUi::GetMousePosY() const {
	return mouse_y;
}
