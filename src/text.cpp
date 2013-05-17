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

void Text::Draw(Bitmap& dest, int x, int y, std::string const& text, Text::Alignment align) {
	if (text.length() == 0) return;

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
	dst_rect.width += 1; dst_rect.height += 1; // Need place for shadow
	if (dst_rect.IsOutOfBounds(dest.width(), dest.height())) return;

	// Where to draw the next glyph (x pos)
	int next_glyph_pos = 0;

	Rect src_rect(0, 0, dst_rect.width, dst_rect.height);
	int iy = dst_rect.y;
	if (dst_rect.height > text_size.height + 1) {
		iy += ((dst_rect.height - text_size.height + 1) / 2);
	}
	int ix = dst_rect.x;

	// This loops always renders a single char, color blends it and then puts
	// it onto the text_surface (including the drop shadow)
	for (boost::u8_to_u32_iterator<std::string::const_iterator>
			 c(text.begin(), text.begin(), text.end()),
			 end(text.end(), text.begin(), text.end()); c != end; ++c) {
		Rect const next_glyph_rect(ix + next_glyph_pos, iy, 0, 0);

		boost::u8_to_u32_iterator<std::string::const_iterator> const next_c_it = boost::next(c);
		uint32_t const next_c = std::distance(c, end) > 1? *next_c_it : 0;

		// ExFont-Detection: Check for A-Z or a-z behind the $
		if (*c == '$' && std::isalpha(next_c)) {
			int const exfont_index =
					std::islower(next_c)? next_c - 'a' + 26:
					std::isupper(next_c)? next_c - 'A':
					-1;
			assert(exfont_index != -1);

			for(size_t y = 0; y < 12; ++y) {
				for(size_t x = 0; x < 12; ++x) {
					if(EASYRPG_EXFONT[exfont_index][y] & (0x01 << x)) {
						// color
						dest.set_pixel(
							next_glyph_rect.x + x, next_glyph_rect.y + y,
							Font::default_color);
					}
				}
			}

			next_glyph_pos += 12;
			// Skip the alphabet part of exfont
			++c;
		} else { // Not ExFont, draw normal text
			dest.font->Render(dest, next_glyph_rect.x, next_glyph_rect.y, *c);
			std::string const glyph(c.base(), next_c_it.base());
			next_glyph_pos += Font::Default()->GetSize(glyph).width;
		}
	}
}

void Text::Draw(Bitmap& dest, int x, int y, int color, std::string const& text, Text::Alignment align) {
	if (text.length() == 0) return;

	FontRef font = dest.font;
	Rect const text_size = Font::Default()->GetSize(text);
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
	BitmapRef system = Cache().System(Data::system.system_name);

	// Where to draw the next glyph (x pos)
	int next_glyph_pos = 0;

	Rect src_rect(0, 0, dst_rect.width, dst_rect.height);
	int iy = dst_rect.y;
	if (dst_rect.height > text_size.height + 1) {
		iy += ((dst_rect.height - text_size.height + 1) / 2);
	}
	int ix = dst_rect.x;

	// This loops always renders a single char, color blends it and then puts
	// it onto the text_surface (including the drop shadow)
	for (boost::u8_to_u32_iterator<std::string::const_iterator>
			 c(text.begin(), text.begin(), text.end()),
			 end(text.end(), text.begin(), text.end()); c != end; ++c) {
		Rect const next_glyph_rect(ix + next_glyph_pos, iy, 0, 0);

		boost::u8_to_u32_iterator<std::string::const_iterator> const next_c_it = boost::next(c);
		uint32_t const next_c = std::distance(c, end) > 1? *next_c_it : 0;

		// ExFont-Detection: Check for A-Z or a-z behind the $
		if (*c == '$' && std::isalpha(next_c)) {
			int const exfont_index =
					std::islower(next_c)? next_c - 'a' + 26:
					std::isupper(next_c)? next_c - 'A':
					-1;
			assert(exfont_index != -1);

			size_t const color_base = (16 - 12) / 2;
			unsigned const
					shadow_x = 16 + color_base, shadow_y = 32 + color_base,
					src_x = color % 10 * 16 + color_base,
					src_y = color / 10 * 16 + 48 + color_base;

			for(size_t y = 0; y < 12; ++y) {
				for(size_t x = 0; x < 12; ++x) {
					if(EASYRPG_EXFONT[exfont_index][y] & (0x01 << x)) {
						// color
						dest.set_pixel(
							next_glyph_rect.x + x, next_glyph_rect.y + y,
							system->get_pixel(src_x + x, src_y + y));
						// shadow
						dest.set_pixel(
							next_glyph_rect.x + x + 1, next_glyph_rect.y + y + 1,
							system->get_pixel(shadow_x + x, shadow_y + y));
					}
				}
			}

			next_glyph_pos += 12;
			// Skip the alphabet part of exfont
			++c;
		} else { // Not ExFont, draw normal text
			font->Render(dest, next_glyph_rect.x, next_glyph_rect.y, *system, color, *c);
			std::string const glyph(c.base(), next_c_it.base());
			next_glyph_pos += Font::Default()->GetSize(glyph).width;
		}
	}
}
