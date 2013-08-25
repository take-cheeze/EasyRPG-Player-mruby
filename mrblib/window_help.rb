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

# Window_Help class.
# Shows skill and item explanations.
class Window_Help < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @align = Text::AlignLeft
    @text = ''
    self.contents = Bitmap.new iw - 16, ih - 16
  end

  # Sets the text that will be shown.
  #
  # @param text text to show.
  # @param align text alignment.
  def set_text(text, align = Text::AlignLeft)
    return if @text == text and @align = align

    contents.clear
    @text = text
    @align = align
    contents.draw_text_2k 0, 2, @text, Font::ColorDefault, @align
  end

  def text=(v); set_text(v); end
end
