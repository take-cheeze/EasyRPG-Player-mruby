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

# Scene_Item class.
class Scene_Name < Scene
  # Constructor.
  def initialize; super 'Name'; end

  def start
    # Create the windows

    @name_window = Window_Name.new 96, 40, 192, 32
    @name_window.set Game_Temp.hero_name
    @name_window.refresh

    @face_window = Window_Face.new 32, 8, 64, 64
    @face_window.set Game_Temp.hero_name_id
    @face_window.refresh

    @kbd_window = Window_Keyboard.new 32, 72, 256, 160
    @kbd_window.mode = Game_Temp.hero_name_charset
    @kbd_window.refresh
    @kbd_window.update_cursor_rect
  end

  def update
    @kbd_window.update
    @name_window.update

    if Input.trigger? Input::CANCEL
      if not name_window.get.empty?
        Game_System.se_play Game_System::SFX_Cancel
        @name_window.erase
      else; Game_System.se_play Game_System::SFX_Buzzer
      end
    elsif Input.trigger? Input::DECISION
      Game_System.se_play Game_System::SFX_Decision
      s = @kbd_window.selected

      assert !s.nil?

      if s == Window_Keyboard::DONE || s == Window_Keyboard::DONE_JP
        Game_Temp.hero_name = @name_window.get
        actor = Game_Actors.actor Game_Temp::hero_name_id
        if  not actor.nil?
          if @name_window.get.empty?
            @name_window.set actor.name
            @name_window.refresh
          else
            @actor.name = @name_window.get
            Player.pop
          end
        end
      elsif s == Window_Keyboard::TO_SYMBOL
        @kbd_window.mode = Window_Keyboard::Symbol
      elsif s == Window_Keyboard::TO_LETTER
        @kbd_window.mode = Window_Keyboard::Letter
      elsif s == Window_Keyboard::TO_HIRAGANA
        @kbd_window.mode = Window_Keyboard::Hiragana
      elsif s == Window_Keyboard::TO_KATAKANA
        @kbd_window.mode = Window_Keyboard::Katakana
      elsif s == Window_Keyboard::SPACE
        @name_window.append ' '
      else; @name_window.append s; end
    end
  end
end
