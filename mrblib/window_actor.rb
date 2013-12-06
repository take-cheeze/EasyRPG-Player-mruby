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
    contents.draw_text_2k 3, 170, Data.term.lvl_short, 1
    contents.draw_text_2k 79, 170, Game_Actors.actor(actor_id).level.to_s, Font::ColorDefault, Text::AlignRight
  end
end

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
    contents.draw_text_2k 1, 3, Data.term.hp_short, 1
    draw_min_max 100,3,actor.hp, actor.max_hp

    # Draw Sp
    contents.draw_text_2k 1, 18, Data.term.sp_short, 1
    draw_min_max 100,18,actor.sp, actor.max_sp

    # Draw Exp
    contents.draw_text_2k 1, 33, Data.term.exp_short, 1
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

# Window_ActorTarget class.
class Window_ActorTarget < Window_Selectable
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    self.contents = Bitmap.new iw - 16, ih - 16
    refresh
  end

  def refresh
    contents.clear

    # DisplayUi.backcolor = Cache().system_info.bg_color

    y_base = 0
    Game_Party_base.actors.each_with_index { |v,i|
      draw_actor_face v, 0, i * 48 + y_base
      draw_actor_name v, 48 + 8, i * 48 + 2 + y_base
      draw_actor_level v, 48 + 8, i * 48 + 2 + 16 + y_base
      draw_actor_state v, 48 + 8, i * 48 + 2 + 16 + 16 + y_base
      draw_actor_hp v, 48 + 8 + 58, i * 48 + 2 + 16 + y_base
      draw_actor_sp v, 48 + 8 + 58, i * 48 + 2 + 16 + 16 + y_base

      y_base += 10
    }
  end

  def update_cursor_rect
    if @index < -10 # Entire Party
        cursor_rect = Rect.new 48 + 4, 0, 120, @item_max * (48 + 10) - 10
    elsif @index < 0 # Fixed to one
      cursor_rect = Rect.new 48 + 4, -@index * (48 + 10), 120, 48
    else
      cursor_rect = Rect.new 48 + 4, @index * (48 + 10), 120, 48
    end
  end
end
