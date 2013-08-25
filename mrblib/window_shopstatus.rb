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

# Window ShopStatus Class.
# Displays possessed and equipped items.
class Window_ShopStatus < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @item_id = 0

    contents = Bitmap.new iw - 16, ih - 16

    refresh
  end

  # Renders the current total on the window.
  def refresh
    contents.clear

    if item_id != 0
      contents.draw_text_2k 0, 2, Data.terms.possessed_items, 1
      contents.draw_text_2k 0, 18, Data.terms.equipped_items, 1

      contents.draw_text_2k 120, 2, Game_Party.item_number(item_id).to_s, Font::ColorDefault, Text::AlignRight
      contents.draw_text_2k 120, 18, Game_Party.item_number(item_id, true).to_s, Font::ColorDefault, Text::AlignRight
    end
  end

  # Sets the item to display.
  #
  # @param item_id ID of item to use.
  def item_id=(new_item_id)
    if new_item_id != @item_id
      @item_id = new_item_id
      refresh()
    end
  end
end
