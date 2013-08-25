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

# Window_Equip class.
# Displays currently equipped items.
class Window_Equip < Window_Selectable
  # Constructor.
  #
  # @param x window x position.
  # @param y window y position.
  # @param w window width.
  # @param h window height.
  # @param actor_id actor whose inventory is displayed.
  def initialize(ix, iy, iw, ih, actor_id)
    super ix, iy, iw, ih
    @actor_id = actor_id
    self.contents = Bitmap.new iw - 16, ih - 16
    @index = 0
    @data = []
    refresh
  end

  # Refreshes.
  def refresh
    contents.clear


    # Add the equipment of the actor to data
    @data.clear
    actor = Game_Actors.actor(@actor_id)
    for i in 0...5; @data.push actor.equipment i; end
    @item_max = data.length

    # Draw equipment text
    for i in 0...5
      draw_equipment_type(actor, 0, (12 + 4) * i + 2, i)
      draw_item_name Data.items[data[i]], 60, (12 + 4) * i + 2 if (data[i] > 0)
    end
  end

  # Returns the item ID of the selected item.
  #
  # @return item ID.
  def item_id; @index < 0 ? 0 : @data[@index]; end

  # Updates the help text.
  def update_help; @help_window.text = item_id == 0 ? '' : Data.items[item_id].description; end
end
