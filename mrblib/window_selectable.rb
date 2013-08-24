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

# Window Selectable class.
class Window_Selectable < Window_Base
	def initialize(x, y, w, h)
    super x, y, w, h
    @item_max = 1
    @column_max = 1
    @index = nil
    @help_window = nil
  end

	# Creates the contents based on how many items
	# are currently in the window.
	def create_contents
    self.contents = Bitmap.new width - 16, [h - 15, row_max * 16].max
  end

  attr_reader :index, :help_window

  def index=(v)
    @index = [v, @item_max - 1].min
    update_help if active and not help_window.nil?
    update_cursor_rect
  end

  def row_max; (@item_max + @column_max - 1) / @column_max; end
  def top_row; oy / 16; end
  def top_row=(row); self.oy = [0, [row, row_max - 1].min].max * 16; end

  def page_row_max; (height - 16) / 16; end
  def page_item_max; page_row_max * @column_max; end

	# Returns the Item Rect used for item drawing.
	#
	# @param index index of item.
	# @return Rect where the item is drawn.
  def item_rect(idx)
    ret = Rect.new
    ret.width = contents.width / @column_max - 4
    ret.height = 12
    ret.x = @index % @column_max * ret.width
    ret.x += 8 if rect.x > 0
    ret.y = @index / @column_max * 16 + 2
    ret
  end

	# Assigns a help window that displays a description
	# about the selected item.
	#
	# @param v the help window.
  def help_window=(v)
    @help_window = v
    update_help if active and not help_window.nil?
  end

	def update_cursor_rect
    cursor_width = 0
    x = 0
    if @index.nil?
      self.cursor_rect rect
      return
    end

    row = @index / @column_max
    if row < top_row
      slef.top_row = row
    elsif row > top_row + (page_row_max - 1)
      self.top_row = row - (page_row_max - 1)
    end

    if @column_max > 1
      cursor_width = (width / column_max - 16) + 12
      x = (index % column_max * cursor_width) - 4
    else
      cursor_width = (width / column_max - 16) + 8
      x = (index % column_max * (cursor_width + 16)) - 4
    end

    y = @index / @column_max * 16 - oy
    self.cursor_rect = Rect.new x, y, cursor_width, 16
  end

	def update
    if (active && @item_max > 0 && @index >= 0)
      if (Input.repeated?(Input::DOWN))
        if ((@column_max == 1 && Input.triggered?(Input::DOWN)) || @index < @item_max - @column_max)
          Game_System.se_play($game_data.system.cursor_se)
          @index = (@index + @column_max) % @item_max
        end
      end
      if (Input.repeated?(Input::UP))
        if ((@column_max == 1 && Input.triggered?(Input::UP)) || @index >= @column_max)
          Game_System.se_play($game_data.system.cursor_se)
          @index = (@index - @column_max + @item_max) % @item_max
        end
      end
      if (Input.repeated?(Input::RIGHT))
        if (@column_max >= 2 && @index < @item_max - 1)
          Game_System.se_play($game_data.system.cursor_se)
          @index += 1
        end
      end
      if (Input.repeated?(Input::LEFT))
        if (@column_max >= 2 && @index > 0)
          Game_System.se_play($game_data.system.cursor_se)
          @index -= 1
        end
      end
    end
    if (active && help_window != nil)
      UpdateHelp()
    end
    update_cursor_rect()
  end

	def update_help; end
end
