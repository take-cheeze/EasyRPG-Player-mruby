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

# Window ActorStatus Class.
# Displays the right hand information window in the status
# scene (HP, MP, EXP).
class Window_ActorStatus < Window_Base
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
    draw_status
  end

  # Draws the actor status
  def draw_status
    actor = Game_Actors.actor @actor_id

    # Draw Hp
    contents.draw_text_2k 1, 3, Data.terms.hp_short, 1
    draw_min_max 100,3,actor.hp, actor.max_hp

    # Draw Sp
    contents.draw_text_2k 1, 18, Data.terms.sp_short, 1
    draw_min_max 100,18,actor.sp, actor.max_sp

    # Draw Exp
    contents.draw_text_2k 1, 33, Data.terms.exp_short, 1
    draw_min_max(100,33, -1, -1)
  end

  # Draws min and max separated by a "/" in cx, cy
  def draw_min_max(cx, cy, min, max)
    if max >= 0; v = min.to_s
    else; v = Game_Actors.actor(@actor_id).exp_string
    end
    contents.draw_text_2k cx, cy, v, Font::ColorDefault, Text::AlignRight
    contents.draw_text_2k cx, cy, "/", Font::ColorDefault

    if max >= 0; v = max
    else; v = Game_Actors.actor(@actor_id).next_exp_string
    end
    contents.draw_text_2k cx+48, cy, v, Font::ColorDefault, Text::AlignRight
  end
end
