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

# Window Shop Number Class.
# The number input window for the shop.
class Window_ShopNumber < Window_Base
  attr_reader :number

	# Constructor.
	#
	# @param x window x position.
	# @param y window y position.
	# @param w window width.
	# @param h window height.
	def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @item_max = 1
    @price = 0
    @number = 1
    @item_id = 0

    contents = Bitmap.new iw - 16, ih - 16
  end

	# Updates the Windows contents.
	def refresh
    contents.clear

    y = 34
    draw_item_name Data.items[item_id], 0, y

    contents.draw_text_2k 132, y, "x", Font::ColorDefault
    contents.draw_text_2k 132 + 30, y, @number.to_s, Font::ColorDefault, Text::AlignRight
    cursor_rect = Rect.new 132 + 14, y - 2, 20, 16

    draw_currency_value(total, contents.width, y + 32)
  end

	# Updates number value according to user input.
	def update
    super

    if active
        int last_number = number
      if Input.repeat?(Input::RIGHT) && number < item_max
        number += 1
      elsif Input.repeat?(Input::LEFT) && number > 1
        number -= 1
      elsif Input.repeat?(Input::UP) && number < item_max
        number = [number + 10, item_max].min
      elsif Input.repeat?(Input::DOWN) && number > 1
        number = [number - 10, 1].max
      end
		end

		if last_number != number
			Game_System.se_play($game_data.system.cursor_se)
			refresh
    end
  end

	# Sets all data needed for the window.
	#
	# @param id item to buy.
	# @param max item maximum quantity.
	# @param price Price of the item.
	# @return the currently input number.
	def set_data(id, max, price)
    @item_id = id
    @item_max = max
    @price = price
    @number = 1
  end

	# Returns the total costs.
	#
	# @return total costs to buy the item.
  def total
    Data.items[@item_id].price * @number
  end
end
