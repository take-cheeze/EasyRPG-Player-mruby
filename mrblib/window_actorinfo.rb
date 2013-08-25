# This file is part of EasyRPG Player.
#
# EasyRPG Player is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# EasyRPG Player is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EasyRPG Player. If not, see <http://www.gnu.org/licenses/>.

# Window ActorInfo Class.
# Displays the left hand information window in the status
# scene.
class Window_ActorInfo < Window_Base
	# Constructor.
  def initialize(ix, iy, iw, ih, actor_id)
    super ix, iy, iw, ih
    @actor_id = actor_id
    self.contents = Bitmap.new iw - 16, ih - 16
    refresh
  end

	# Renders the stats on the window.
	def refresh
    contents.clear
    draw_info
  end

	# Draws the actor face and information
  def draw_info
    # Draw Row formation.
    battle_row = Game_Actors.actor(@actor_id).battle_row == 1 ? "Back" : "Front"
    contents.draw_text_2k contents.width, 5, battle_row, Font::ColorDefault, Text::AlignRight

    # Draw Face
    draw_actor_face Game_Actors.actor(@actor_id), 0, 0

    # Draw Name
    contents.draw_text_2k 3, 50, "Name", 1
    draw_actor_name Game_Actors.actor(@actor_id), 36, 65

    # Draw Profession
    contents.draw_text_2k 3, 80, "Profession", 1
    draw_actor_class Game_Actors.actor(@actor_id), 36, 95

    # Draw Rank
    contents.draw_text_2k 3, 110, "Title", 1
    draw_actor_title Game_Actors.actor(@actor_id), 36, 125

    # Draw Status
    contents.draw_text_2k 3, 140, "Status", 1
    draw_actor_state Game_Actors.actor(@actor_id), 36, 155

    # Draw Level
    contents.draw_text_2k 3, 170, Data.terms.lvl_short, 1
    contents.draw_text_2k 79, 170, Game_Actors.actor(actor_id).level.to_s, Font::ColorDefault, Text::AlignRight
  end
end
