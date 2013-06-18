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

#if defined(USE_SDL)
#  include "platform/sdl_ui.cpp"
#elif defined(EASYRPG_IS_ANDROID)
#  include "platform/android_ui.cpp"
#else
#  error "no UI implementation available"
#endif

// Headers
#include "baseui.h"
#include "system.h"
#include "font.h"
#include "graphics.h"
#include "bitmap.h"

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

void BaseUi::DrawScreenText(const std::string &text) {
	DrawScreenText(text, 12, 12);
}

void BaseUi::DrawScreenText(const std::string &text, int x, int y, Color const& color) {
	Bitmap& buf = *Graphics().ScreenBuffer();
	Font::default_color = color;
	buf.font = Font::Shinonome();

	unsigned line = 0;
	std::string::const_iterator i = text.begin();
	do {
		std::string const line_str(i, std::find(i, text.end(), '\n'));
		buf.draw_text(x, y + buf.font->pixel_size() * line++, line_str);
		std::advance(i, line_str.size() + 1);
	} while(i < text.end());
}
