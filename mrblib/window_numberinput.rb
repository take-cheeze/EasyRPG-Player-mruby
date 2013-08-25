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

# Window Input Number Class.
# The number input window.
class Window_NumberInput < Window_Selectable
  # Constructor.
  #
  # @param ix window x position.
  # @param iy window y position.
  # @param iwidth window width.
  # @param iheight window height.
  def initialize(x, y, w = 320, h = 80)
    super ix, iy, iw, ih
    @max_digits = 6
    @number = 0

    self.contents = Bitmap.new iw - 16, ih - 16
    @cursor_width = 14
    self.z = 10001
    @opacity = 0
    @index = 0
    self.active = false

    refresh
    update_cursor_rect
  end

  # Updates the Window's contents.
  def refresh
    contents.clear
    str = "%0#{@max_digits}" % @number
    for i in 0...@max_digits
      contents.draw_text_2k i * (cursor_width - 2) + 12, 2, str[i], Font::ColorDefault
    end
  end

  attr_reader :number, :max_digits

  # Sets a new number value.
  #
  # @param val the new number value.
  def number=(val)
    max = 0...@max_digits.reduce(1) { |tmp,v| tmp * 10 } - 1
    @number = [0, [val, max].min].max
    @index = 0
    refresh
  end

  # Sets the maximal displayed digits.
  #
  # @param v maximal displayed digits
  #                    must be a value from 1-6.
  def max_digits=(v)
    @max_digits = [1, [v, 6].min].max
    @index = 0
    refresh
  end

  # Updates the position of the cursor rectangle.
  def update_cursor_rect
    @cursor_rect = Rect.new @index * (@cursor_width - 2) + 8, 0, @cursor_width, 16
  end

  # Updates number value according to user input.
  def update
    super

    return if not active

    if Input.repeat?(Input::DOWN) || Input.repeat?(Input_::UP)
      Game_System.se_play $game_data.system.cursor_se

      place = 0...(@max_digits - 1 - @index).reduce(1) { |tmp,v| tmp * 10 }
      n = @number / place % 10
      @number -= n * place
      n = (n + 1) % 10 if Input.repeat? Input_::UP
      n = (n + 9) % 10 if Input.repeat? Input_::DOWN
      @number += n * place
      refresh()
    end

    if Input.repeat? Input::RIGHT and max_digits >= 2
      Game_System.se_play $game_data.system.cursor_se
      @index = (@index + 1) % @max_digits
    end

    if Input.repeat? Input_::LEFT
      Game_System.se_play($game_data.system.cursor_se)
      @index = (@index + @max_digits - 1) % @max_digits
    end

    update_cursor_rect
  end
end
