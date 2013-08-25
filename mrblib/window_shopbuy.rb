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

# Window Shop Buy Class
# The shop item list window.
class Window_ShopBuy < Window_Selectable
  # Constructor.
  def initialize(x, y, w = 320, h = 80)
    super ix, iy, iw, ih
    @index = 0
  end

  # Gets item ID of the selected item.
  #
  # @return current selected item ID.
  def item_id
    index < 0 ? 0 : data[index]
  end

  # Refreshes the item list.
  def refresh
    @data = Game_Temp.shop_goods
    @item_max = data.length

    create_contents
    contents.clear

    for i in 0...data.length; draw_item i; end
  end

  # Draws an item together with the price.
  #
  # @param index index of item to draw.
  def draw_item(index)
    id = data[index]
    enabled = Data.items[id].price <= Game_Party.gold
    rect = item_rect(index)
    contents.fill rect, Color.new()
    draw_item_name Data.items[id], rect.x, rect.y, enabled

    contents.draw_text_2k rect.width + 4, rect.y, Data.items[id].price.to_s, enabled ? Font::ColorDefault : Font::ColorDisabled, Text::AlignRight
  end

  # Updates the help window.
  def update_help
    help_window.text = item_id == 0 ? ""  : Data.items[item_id].description
  end

  # Checks if the item should be enabled.
  #
  # @param item_id item id to check.
  # @return true if it is enabled.
  def check_enable(id)
    id > 0 and
      Data.items[id].price <= Game_Party.gold and
      Game_Party.item_number(id) < 99
  end
end
