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
#include "bitmap.h"
#include "bot_ui.h"
#include "lua_bot.h"
#include "player.h"
#include "output.h"
#include "input.h"
#include "utils.h"
#include "graphics.h"

#include <boost/chrono.hpp>
#include <boost/thread.hpp>
#include <stdint.h>


BotUi::BotUi(EASYRPG_SHARED_PTR<BotInterface> const& inf)
	: bot_(inf), counter_(0)
{
	current_display_mode.width = SCREEN_TARGET_WIDTH;
	current_display_mode.height = SCREEN_TARGET_HEIGHT;
}

void BotUi::ProcessEvents() {
	if(bot_->is_finished()) {
		Player().exit_flag = true;
		return;
	}

	// interval: 0.1ms
	static const size_t INTERVAL = 6;

	if(counter_++ > INTERVAL) {
		keys.reset();
		counter_ = 0;

		if(Input().IsWaitingInput()) {
			assert(!bot_->is_finished());
			bot_->resume();
		}
	}
}

uint32_t BotUi::GetTicks() const {
	using namespace boost::chrono;
	return duration_cast<milliseconds>
		(system_clock::now().time_since_epoch()).count();
}

void BotUi::Sleep(uint32_t time) {
	boost::this_thread::sleep_for(boost::chrono::milliseconds(time));
}

AudioInterface& BotUi::GetAudio() {
	return audio_;
}
