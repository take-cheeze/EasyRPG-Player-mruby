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
#include <iomanip>
#include <sstream>
#include "window_actorinfo.h"
#include "game_actor.h"
#include "game_actors.h"
#include "game_party.h"
#include "bitmap.h"
#include "font.h"
#include "data.h"

Window_ActorInfo::Window_ActorInfo(int ix, int iy, int iwidth, int iheight, int actor_id) :
	Window_Base(ix, iy, iwidth, iheight),
	actor_id(actor_id) {

	SetContents(Bitmap::Create(width - 16, height - 16));

	Refresh();
}

void Window_ActorInfo::Refresh() {
	contents->clear();

	DrawInfo();
}

void Window_ActorInfo::DrawInfo() {
	// Draw Row formation.
	std::string battle_row = Game_Actors::GetActor(actor_id)->GetBattleRow() == 1 ? "Back" : "Front";
	contents->draw_text(contents->width(), 5, battle_row, Font::ColorDefault, Text::AlignRight);

	// Draw Face
	DrawActorFace(Game_Actors::GetActor(actor_id), 0, 0);

	// Draw Name
	contents->draw_text(3, 50, "Name", 1);
	DrawActorName(Game_Actors::GetActor(actor_id), 36, 65);

	// Draw Profession
	contents->draw_text(3, 80, "Profession", 1);
	DrawActorClass(Game_Actors::GetActor(actor_id), 36, 95);

	// Draw Rank
	contents->draw_text(3, 110, "Title", 1);
	DrawActorTitle(Game_Actors::GetActor(actor_id), 36, 125);

	// Draw Status
	contents->draw_text(3, 140, "Status", 1);
	DrawActorState(Game_Actors::GetActor(actor_id), 36, 155);

	//Draw Level
	contents->draw_text(3, 170, Data::terms.lvl_short, 1);
	std::ostringstream ss;
	ss << Game_Actors::GetActor(actor_id)->GetLevel();
	contents->draw_text(79, 170, ss.str(), Font::ColorDefault, Text::AlignRight);
}
