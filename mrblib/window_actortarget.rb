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
