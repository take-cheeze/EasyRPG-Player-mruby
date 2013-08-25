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

# Scene End class.
# Displays the "Do you really want to exit?" text.
class Scene_End < Scene
  # Constructor.
  def initialize; super 'End'; end

  def start
    create_command_window
    create_help_window

    @background = Scene_Menu.create_background
  end

  def update
    @command_window.update

    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      Scene.pop # Select End Game
    elsif Input.trigger? Input::DECISION
      Game_System.se_play $game_data.system.decision_se
      case @command_window.index
      when 0 # Yes
        Audio.bgm_fade 800
        Audio.bgs_fade 800
        Audio.me_fade 800
        Scene.pop_until 'Title'
      when 1 # No
        Scene.pop
      end
    end
  end

  # Creates the Window displaying the yes and no option.
  def create_command_window
    # Create Options Window
    @command_window = Window_Command.new [Data.terms.yes, Data.terms.no]
    @command_window.x = 160 - @command_window.width / 2
    @command_window.y = 72 + 48
  end

  # Creates the Window displaying the confirmation
  # text.
  def create_help_window
    text_size = Font.default.size(Data.terms.exit_game_message).width

    @help_window = Window_Help.new 160 - (text_size + 16)/ 2, 72, text_size + 16, 32
    @help_window.text = Data.terms.exit_game_message

    @command_window.help_window = @help_window
  end
end
