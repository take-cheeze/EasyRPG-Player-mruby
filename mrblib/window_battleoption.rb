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

# Window_BattleOption class.
class Window_BattleOption < Window_Base
	# Constructor.
  def initialize(x, y, w, h)
    super x, y, w, h

    self.contents = Bitmap.new w - 16, h - 16

    # @commands = [Data.terms.battle_fight, Data.terms.battle_auto, Data.terms.battle_escape]
    @commands = ["Victory", "Defeat", "Escape"]


    @index = nil
    @top_row = 0
    @num_rows = contents.height

    refresh
  end

  attr_accessor :index

	# Refreshes the window contents.
	def refresh
    contents.clear

    draw_item 0, Font::ColorDefault
    draw_item 1, Game_Temp.battle_defeat_mode == 0 ? Font::ColorDisabled : Font::ColorDefault
    draw_item 2, Game_Temp.battle_escape_mode == 0 ? Font::ColorDisabled : Font::ColorDefault

    #for (int i = 0; i < (int) commands.size(); i++)
    #	Font::SystemColor color = (i == 2 && Game_Temp::battle_escape_mode == 0)
    #		? Font::ColorDisabled
    #		: Font::ColorDefault
    #	DrawItem(i, color)
    #end
  end

	# Updates the window state.
	def update
    super

    if @active && @num_commands >= 0 && (not @index.nil?)
      if Input.repeat? Input::DOWN
        Game_System.se_play $game_data.system.cursor_se
        @index += 1
      end

      if Input.repeat? Input::UP
        Game_System.se_play $game_data.system.cursor_se
        index -= 1
      end

      @index += @commands.length
      @index %= @commands.length

      @top_row = @index if @index < @top_row
      @top_row = @index - @num_rows + 1 if @index > @top_row + @num_rows - 1
    end

    update_cursor_rect
  end

  def active=(v)
    @index = v ? 0 : nil
    @top_row = 0
    Window.active = v
    refresh
  end

  def update_cursor_rect
    if @index.nil?
      self.cursor_rect = Rect.new
    else
      self.cursor_rect = Rect.new 0, (@index - @top_row) * 16, contents.width, 16
    end
  end

  def draw_item(idx, color)
    y = 16 * (@index - @top_row)
    return if y < 0 or y + 16 > contents.height
    contents.fill Rect.new(0, y, contents.width, 16), Color.new
    contents.draw_text_2k 2, y + 2, @commands[@index], color
  end
end
