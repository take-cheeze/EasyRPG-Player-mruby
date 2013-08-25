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

# Window Name Class.
class Window_Name < Window_Base
	# Constructor.
	def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    self.contents = Bitmap.new iw - 16, ih - 16
    @name = ''
    refresh
  end

	# Renders the current name on the window.
	def refresh
    contents.clear
    contents.draw_text_2k 2, 2, @name, Font::ColorDefault
  end

	def set(text)
    @name = text
    refresh
  end

	def append(text)
    if contents.text_size(name + text).width <= (12 * 6)
      @name += text
      refresh
    else
      Game_System.se_play $game_data.system.buzzer_se
    end
  end

  def get; @name; end

	def update
    self.cursor_rect = Rect.new contents.text_size(@name).width + 2, 0, 16, 16
  end

  def erase
    return if @name.empty?

    # remove one UTF-8 char
    # boost::u8_to_u32_iterator<std::string::const_iterator> name_begin =
    #   boost::u8_to_u32_iterator<std::string::const_iterator>(name.begin(), name.begin(), name.begin())
    # boost::u8_to_u32_iterator<std::string::const_iterator> name_end =
    #   boost::u8_to_u32_iterator<std::string::const_iterator>(name.end(), name.begin(), name.end())
    # --name_end
    # @name = std::string(name_begin.base(), name_end.base())

    @name = @name[1, @name.length - 1]

    refresh
  end
end
