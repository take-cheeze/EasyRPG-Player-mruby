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
#include "data.h"
#include "cache.h"
#include "output.h"
#include "utils.h"
#include "bitmap.h"
#include "font.h"
#include "text.h"
#include "exfont.hxx"

#include <cctype>

#include <boost/next_prior.hpp>
#include <boost/regex/pending/unicode_iterator.hpp>

namespace {

unsigned to_exfont_index(char const c) {
	int const ret =
			std::islower(c)? c - 'a' + 26:
			std::isupper(c)? c - 'A':
			-1;
	assert(ret != -1);
	return ret;
}

typedef boost::u8_to_u32_iterator<std::string::const_iterator> u8_to_u32_iterator;

}

void Text::Draw(Bitmap& dest, int const x, int const y, std::string const& text, Text::Alignment align) {
	if (text.empty()) return;

	Rect const text_size = dest.text_size(text);
	Rect dst_rect = text_size;

	switch (align) {
	case Text::AlignCenter:
		dst_rect.x = x - dst_rect.width / 2; break;
	case Text::AlignRight:
		dst_rect.x = x - dst_rect.width; break;
	case Text::AlignLeft:
		dst_rect.x = x; break;
	default: assert(false);
	}

	dst_rect.y = y;
	if (dst_rect.height > text_size.height + 1) {
		dst_rect.y += ((dst_rect.height - text_size.height + 1) / 2);
	}

	// This loops always renders a single char, color blends it and then puts
	// it onto the text_surface (including the drop shadow)
	for (u8_to_u32_iterator
				 c(text.begin(), text.begin(), text.end()),
				 end(text.end(), text.begin(), text.end()); c != end; ++c) {
		u8_to_u32_iterator const next_c_it = boost::next(c);
		uint32_t const next_c = std::distance(c, end) > 1? *next_c_it : 0;

		// ExFont-Detection: Check for A-Z or a-z behind the $
		if (*c == '$' && std::isalpha(next_c)) {
			unsigned const exfont_index = to_exfont_index(next_c);

			for(size_t font_y = 0; font_y < 12; ++font_y) {
				for(size_t font_x = 0; font_x < 12; ++font_x) {
					if(EASYRPG_EXFONT[exfont_index][font_y] & (0x01 << font_x)) {
						// color
						dest.set_pixel(
							dst_rect.x + font_x, dst_rect.y + font_y,
							Font::default_color);
					}
				}
			}

			dst_rect.x += 12;
			// Skip the alphabet part of exfont
			++c;
		} else { // Not ExFont, draw normal text
			dest.font->Render(dest, dst_rect.x, dst_rect.y, *c);
			dst_rect.x += dest.font->GetSize(*c).width;
		}
	}
}

void Text::Draw(Bitmap& dest, int x, int y, int color, std::string const& text, Text::Alignment align) {
	if (text.empty()) return;

	Rect const text_size = dest.font->GetSize(text);
	Rect dst_rect = text_size;

	switch (align) {
	case Text::AlignCenter:
		dst_rect.x = x - dst_rect.width / 2; break;
	case Text::AlignRight:
		dst_rect.x = x - dst_rect.width; break;
	case Text::AlignLeft:
		dst_rect.x = x; break;
	default: assert(false);
	}

	dst_rect.y = y;
	dst_rect.width += 1; dst_rect.height += 1; // Need place for shadow
	if (dst_rect.IsOutOfBounds(dest.width(), dest.height())) return;

	// Load the system file for the shadow and text color
	BitmapRef const system = Cache().System(Data::system.system_name);

	if (dst_rect.height > text_size.height + 1) {
		dst_rect.y += ((dst_rect.height - text_size.height + 1) / 2);
	}

	// This loops always renders a single char, color blends it and then puts
	// it onto the text_surface (including the drop shadow)
	for (u8_to_u32_iterator
				 c(text.begin(), text.begin(), text.end()),
				 end(text.end(), text.begin(), text.end()); c != end; ++c) {
		u8_to_u32_iterator const next_c_it = boost::next(c);
		uint32_t const next_c = std::distance(c, end) > 1? *next_c_it : 0;

		// ExFont-Detection: Check for A-Z or a-z behind the $
		if (*c == '$' && std::isalpha(next_c)) {
			unsigned const exfont_index = to_exfont_index(next_c);

			size_t const color_base = (16 - 12) / 2;
			unsigned const
					shadow_x = 16 + color_base, shadow_y = 32 + color_base,
					src_x = color % 10 * 16 + color_base,
					src_y = color / 10 * 16 + 48 + color_base;

			for(size_t font_y = 0; font_y < 12; ++font_y) {
				for(size_t font_x = 0; font_x < 12; ++font_x) {
					if(EASYRPG_EXFONT[exfont_index][font_y] & (0x01 << font_x)) {
						// color
						dest.set_pixel(
							dst_rect.x + font_x, dst_rect.y + font_y,
							system->get_pixel(src_x + font_x, src_y + font_y));
						// shadow
						dest.set_pixel(
							dst_rect.x + font_x + 1, dst_rect.y + font_y + 1,
							system->get_pixel(shadow_x + font_x, shadow_y + font_y));
					}
				}
			}

			dst_rect.x += 12;
			// Skip the alphabet part of exfont
			++c;
		} else { // Not ExFont, draw normal text
			dest.font->Render(dest, dst_rect.x, dst_rect.y, *system, color, *c);
			dst_rect.x += dest.font->GetSize(*c).width;
		}
	}
}
