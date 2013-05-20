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
#include <sstream>
#include "window_targetstatus.h"
#include "game_party.h"
#include "font.h"
#include "bitmap.h"

Window_TargetStatus::Window_TargetStatus(int ix, int iy, int iwidth, int iheight) :
	Window_Base(ix, iy, iwidth, iheight), id(-1), use_item(false) {

	SetContents(Bitmap::Create(width - 16, height - 16));
}

void Window_TargetStatus::Refresh() {
	contents->clear();

	if (id < 0) {
		return;
	}

	if (use_item) {
		contents->draw_text(0, 0, Data::terms.possessed_items, 1);
	} else {
		contents->draw_text(0, 0, Data::terms.sp_cost, 1);
	}

	std::ostringstream ss;
	if (use_item) {
		ss << Game_Party::ItemNumber(id);
	} else {
		ss << Data::skills[id - 1].sp_cost;
	}

	contents->draw_text(contents->width() - contents->text_size(ss.str()).width, 0, ss.str(), Font::ColorDefault, Text::AlignRight);
}

void Window_TargetStatus::SetData(int id, bool is_item) {
	this->id = id;
	use_item = is_item;

	Refresh();
}
