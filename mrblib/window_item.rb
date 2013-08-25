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

# Window_Item class.
class Window_Item < Window_Selectable
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @column_max = 2
    @data = []
  end

  # Gets item ID of the selected item.
  #
  # @return current selected item ID.
  def item_id
    @index.nil? ? 0 : data[@index]
  end

  # Checks if the item should be in the list.
  #
  # @param id item to check.
  def check_include(id)
    # TODO:
    # if (Game_Temp::InBattle())
    #   return item_id == Rpg::Item

    @data.empty? and id == 0 ? true : id == 0
  end

  # Checks if item should be enabled.
  #
  # @param id item to check.
  def check_enable(id); Game_Party.item_usable? id; end

  # Refreshes the item list.
  def refresh
    @data.clear
    Game_Party.items.each { |v|
      @data.push v if check_include v
    }
    for i in 0...party_items.length
      data.push
    end

    @data.push 0 if check_include 0

    @item_max = @data.length

    create_contents
    contents.clear
    for i in 0...@item_max; draw_item i; end
  end

  # Draws an item together with the quantity.
  #
  # @param idx index of item to draw.
  def draw_item(idx)
    rect = item_rect idx
    contents.fill rect, Color.new

    item_id = data[idx]

    return if item_id <= 0

    enabled = check_enable item_id
    draw_item_name Data.items[item_id], rect.x, rect.y, enabled

    color = enabled ? Font::ColorDefault : Font::ColorDisabled
    contents.draw_text_2k rect.x + rect.width - 28, rect.y, "x", color
    contents.draw_text_2k(rect.x + rect.width - 6, rect.y,
                       Game_Party.item_number(item_id).to_s, color, Text::AlignRight)
  end

  # Updates the help window.
  def update_help
    @help_window.text = item_id == 0 ? '' : Data.items[item_id].description
  end
end
