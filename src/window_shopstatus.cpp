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
#include <string>
#include <sstream>
#include "game_party.h"
#include "window_shopstatus.h"
#include "bitmap.h"
#include "font.h"

Window_ShopStatus::Window_ShopStatus(int ix, int iy, int iwidth, int iheight) :
	Window_Base(ix, iy, iwidth, iheight), item_id(0) {

	SetContents(Bitmap::Create(width - 16, height - 16));

	Refresh();
}

void Window_ShopStatus::Refresh() {
	contents->clear();

	if (item_id != 0) {
		int number = Game_Party::ItemNumber(item_id);

		contents->draw_text(0, 2, Data::terms.possessed_items, 1);
		contents->draw_text(0, 18, Data::terms.equipped_items, 1);

		std::stringstream ss;
		ss << number;

		contents->draw_text(120, 2, ss.str(), Font::ColorDefault, Text::AlignRight);

		ss.str("");
		ss << Game_Party::ItemNumber(item_id, true);
		contents->draw_text(120, 18, ss.str(), Font::ColorDefault, Text::AlignRight);
	}
}

void Window_ShopStatus::SetItemId(int new_item_id) {
	if (new_item_id != item_id) {
		item_id = new_item_id;
		Refresh();
	}
}
