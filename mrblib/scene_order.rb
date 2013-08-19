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

# Scene Order class.
# Allows changing the order of the party actors.
class Scene_Order < Scene
	# Constructor.
  def initialize
    super 'Order'
    @actor_counter = 0
  end

  def start
    @actors = Array.new Game_Party.actors.length, 0
    create_command_window
  end

  def update
    @window_left.update
    @window_right.update
    @window_confirm.update

    if @window_left.active; update_order
    elsif @window_confirm.active; update_confirm
    end
  end

  def create_command_window
    options_left = []
    options_right = []
    Game_Party.actors.each { |v|
      options_left.push v.name
      options_right.push ''
    }

    # Are they stored anywhere in terms?
    options_confirm = ['Confirm', 'Redo']

    @window_left = Window_Command.new options_left, 88, 4
    @window_left.x = 68
    @window_left.y = 48

    @window_right = Window_Command.new options_right, 88, 4
    @window_right.x = 164
    @window_right.y = 48
    @window_right.active = false
    @window_right.index = nil

    @window_confirm = Window_Command.new options_confirm, 80
    @window_confirm.x = 120
    @window_confirm.y = 144
    @window_confirm.active = false
    @window_confirm.visible = false
  end

  def update_order
    if Input.triggered? Input::CANCEL
      Game_System.se_play Main_Data.game_data.system.cancel_se
      Scene.pop
    elsif Input.triggered? Input::DECISION
      if not actors.find(@window_left.index + 1).nil?
        Game_System.se_play Main_Data.game_data.system.cancel_se
      else
        Game_System.se_play Main_Data.game_data.system.decision_se
        @window_left.set_item_text @window_left.index, ""
        @window_right.set_item_text @actor_counter, Game_Party.actors[@window_left.index].name

        @actors[@actor_counter] = @window_left.index + 1

        @actor_counter += 1

        # Display Confirm/Redo window
        if @actor_counter == Game_Party.actors.length
          @window_left.index = nil
          @window_left.active = false
          @window_confirm.index = 0
          @window_confirm.active = true
          @window_confirm.visible = true
        end
      end
    end
  end

  def update_confirm
    if Input.triggered? Input::CANCEL; redo
    elsif Input.triggered? Input::DECISION
      if @window_confirm.index == 0
        confirm
        Scene.pop
      else; redo
      end
    end
  end

  def redo
    Game_System.se_play Main_Data.game_data.system.cancel_se

    Game_Party.actors.each_with_index { |v,i|
      @window_left.set_item_text i, v.name
      @window_right.set_item_text i, ''
    }

    @window_left.active = true
    @window_left.index = 0

    @window_confirm.active = false
    @window_confirm.visible = false
    @window_confirm.index = nil

    @actor_counter = 0
    @actors = Array.new Game_Party.actors.length
  end

  def confirm
    Game_System.se_play Main_Data.game_data.system.decision_se

    Game_Party.actors.each_with_index { |v,i|
      Game_Party.actors[i] = @actors[i] - 1
    }

    # TODO: Where is the best place to overwrite the character map graphic?
  end
end
