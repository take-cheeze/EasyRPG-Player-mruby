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

# Scene Menu class.
class Scene_Menu < Scene
	# Constructor.
	#
	# @param menu_index selected index in the menu.
	def initialize(menu_index = 0)
    super 'Menu'
    @menu_index = menu_index
    @command_options = []
  end

  def start
    create_command_window

    # Gold Window
    @gold_window = Window_Gold.new 0, 208, 88, 32

    # Status Window
    @menustatus_window = Window_MenuStatus.new 88, 0, 232, 240
    @menustatus_window.active = false

    @background = create_background
  end

	def continue
    @menustatus_window.refresh if @command_options[@command_window.index] == Order
  end

  def update
    @command_window.update
    @gold_window.update
    @menustatus_window.update

    if @command_window.active; update_command
    elsif @menustatus_window.active; update_actor_selection
    end
  end

	# Creates the window displaying the options.
  def create_command_window
    # Create Options Window

    if Player.rpg2k?; @command_options = [Item, Skill, Equipment, Save, Quit]
    else
      @command_options = []
      Data.system.menu_commands.each { |v| @command_options.push v }
      @command_options.push Quit
    end

    # Add all menu items
    options = []
    @command_options.each { |v|
      case v
      when Item; options.push(Data.terms.command_item)
      when Skill; options.push(Data.terms.command_skill)
      when Equipment; options.push(Data.terms.menu_equipment)
      when Save; options.push(Data.terms.menu_save)
      when Status; options.push(Data.terms.status)
      when Row; options.push(Data.terms.row)
      when Order; options.push(Data.terms.order)
      when Wait; options.push(Game_Temp::battle_wait ? Data.terms.wait_on : Data.terms.wait_off)
      else; options.push(Data.terms.menu_quit)
      end
    }

    @command_window = Window_Command.new options, 88
    @command_window.index = menu_index

    # Disable items
    @command_options.each_with_index { |v,i|
      case v
      when Save
        # If save is forbidden disable this item
        @command_window.disable_item i if !Game_System.allow_save?
      when Wait, Quit
      when Order
        @command_window.disable_item i if Game_Party.actors.length <= 1
        break
      else
        @command_window.disable_item i if Game_Party.actors.empty?
      end
    }
  end

	# Update function if command window is active.
  def update_command
    if Input.triggered? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      Scene.pop
    elsif Input.triggered? Input::DECISION
      menu_index = @command_window.index

      case @command_options[menu_index]
      when Item
        if Game_Party.actors.empty?
          Game_System.se_play $game_data.system.buzzer_se
        else
          Game_System.se_play $game_data.system.decision_se
          Scene.push Scene_Item.new
        end
      when Skill, Equipment, Status, Row
        if Game_Party.actors.empty?
          Game_System.se_play $game_data.system.buzzer_se
        else
          Game_System.se_play $game_data.system.decision_se
          @command_window.active = false
          @menustatus_window.active = true
          @menustatus_window.index = 0
        end
      when Save
        if !Game_System.allow_save?
          Game_System.se_play $game_data.system.buzzer_se
        else
          Game_System.se_play $game_data.system.decision_se
          Scene.push Scene_Save.new
        end
      when Order
        if Game_Party.actors.length <= 1
          Game_System.se_play $game_data.system.buzzer_se
        else
          Game_System.se_play $game_data.system.decision_se
          Scene.push Scene_Order.new
        end
      when Wait
        Game_System.se_play $game_data.system.decision_se
        Game_Temp.battle_wait = !Game_Temp.battle_wait
        @command_window.set_item_text menu_index, Game_Temp.battle_wait ? Data.terms.wait_on : Data.terms.wait_off
      when Quit
        Game_System.se_play $game_data.system.decision_se
        Scene.push Scene_End.new
      end
    end
  end

	# Update function if status window is active.
  def update_actor_selection
    if Input.triggered? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      @command_window.active = true
      @menustatus_window.active = false
      @menustatus_window.index = nil
    elsif Input.triggered? Input::DECISION
      Game_System::SePlay($game_data.system.decision_se)
      case @command_options[@command_window.index]
      when Skill; Scene.push Scene_Skill.new(@menustatus_window.index)
      when Equipment; Scene.push Scene_Equip.new(@menustatus_window.index)
      when Status; Scene.push Scene_Status.new(@menustatus_window.index)
      when Row
        actor = Game_Party.actors[@menustatus_window.index]
        actor.battle_row.nil? ?
				actor.battle_row = 1 : actor.battle_row = nil
        @menustatus_window.refresh
      else; assert(false)
      end

      @command_window.active = true
      @menustatus_window.active = false
      @menustatus_window.index = nil
    end
  end

	# Options available in a Rpg2k3 menu.
  Item = 1
  Skill = 2
  Equipment = 3
  Save = 4
  Status = 5
  Row = 6
  Order = 7
  Wait = 8
  Quit = 9

	def self.create_background
    ret = Sprite.new
    ret.bitmap = Bitmap.new SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT
    ret.bitmap.stretch_blit(ret.bitmap.rect, Cache.system(Game_System.system_name),
                            Rect.new(0, 32, 16, 16), 255)
    ret.z = -1000
    ret
  end
end
