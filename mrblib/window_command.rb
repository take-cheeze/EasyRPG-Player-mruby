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

# Window Command class.
class Window_Command < Window_Selectable
  # Constructor.
  #
  # @param commands commands to display.
  # @param width window width, if no width is passed
  #              the width is autocalculated.
  # @param max_item forces a window height for max_item
  #                 items, if no height is passed
  #                 the height is autocalculated.
  def initialize(commands, width = nil, max_item = nil)
    super 0, 0, required_width(commands, width), (max_item.nil? ? commands.length : max_item) * 16 + 16

    @commands = commands
    @index = 0
    @item_max = @commands.length

    self.contents = Bitmap.new self.width - 16, @item_max * 16

    refresh
  end

  # Refreshes the window contents.
  def refresh
    contents.clear
    for i in 0...@item_max; draw_item i, Font::ColorDefault; end
  end

  # Disables a command.
  #
  # @param idx command index.
  def disable_item(idx)
    draw_item idx, Font::ColorDisabled
  end

  # Replaces the text of an item.
  #
  # @param idx command index.
  # @param text new item text.
  def set_item_text(idx, text)
    return if @index >= @commands.length

    @commands[@index] = text
    draw_item @index, Font::ColorDefault
  end

  def draw_item(idx, color)
    contents.fill_rect Rect.new(0, 16 * idx, contents.width - 0, 16), Color.new(0, 0, 0, 0)
    contents.draw_text_2k 0, 16 * idx + 2, @commands[idx], color
  end

  def required_width(commands, width)
    return width unless width.nil?
    bmp = Bitmap.new 1, 1
    commands.reduce(0) { |tmp,v| [tmp, bmp.text_size(v).width].max } + 16
  end
end
