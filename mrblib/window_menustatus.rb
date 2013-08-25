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

# Window MenuStatus Class
class Window_MenuStatus < Window_Selectable
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    self.contents = Bitmap.new iw - 16, ih - 16
    refresh
  end

  def refresh
    contents.clear

    # DisplayUi->SetBackcolor(Cache().system_info.bg_color)

    y = 0
    for i in 0...Game_Party.actor.length
      actor = Game_Party.actors[i]

      face_x = 0
      face_x = actor.battle_row == 1 ? 5 : 0 if Player.rpg2k3?
      draw_actor_face actor, face_x, i*48 + y

      draw_actor_name actor, 48 + 8, i*48 + 2 + y
      draw_actor_title actor, 48 + 8 + 88, i*48 + 2 + y
      draw_actor_level actor, 48 + 8, i*48 + 2 + 16 + y
      draw_actor_state actor, 48 + 8 + 42, i*48 + 2 + 16 + y
      draw_actor_exp actor, 48 + 8, i*48 + 2 + 16 + 16 + y
      draw_actor_hp actor, 48 + 8 + 106, i*48 + 2 + 16 + y
      draw_actor_sp actor, 48 + 8 + 106, i*48 + 2 + 16 + 16 + y

      y += 10
    end
  end

  def update_cursor_rect
    if @index.nil?; @cursor_rect = Rect.new 0, 0, 0, 0
    else @cursor_rect = Rect.new 48 + 4, @index * (48 + 10), 168, 48
    end
  end
end
