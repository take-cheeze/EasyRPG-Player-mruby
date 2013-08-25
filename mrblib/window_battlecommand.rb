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

# Window_BattleCommand class.
class Window_BattleCommand < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih

    self.contents = Bitmap.new iw - 16, ih - 16
    self.actor = 0

    @disabled = Array.new @commands.length
    @index = nil
    @top_row = 0
    @cycle = 0
    @num_rows = contents.height / 16

    refresh
  end

  attr_accessor :index

  # Refreshes the window contents.
  def refresh
    return if (not contents)

    contents.clear
    for i in 0...@commands.length
      DrawItem(i, @disabled[i] ? Font::ColorDisabled : Font::ColorDefault)
    end

    self.up_arrow = false
    self.down_arrow = false
    if (@active && (@cycle / 20) % 2 == 0)
      self.up_arrow = true if @top_row > 0
      self.down_arrow = true if @top_row + @num_rows < @commands.length
    end
  end

  # Updates the window state.
  def update
    super

    old_index = @index
    if @active && @commands.length >= 0 && @index >= 0
      if Input.repeat? Input::DOWN
        Game_System.se_play Main_Datagame_data.system.cursor_se
        index += 1
      end

      if Input.repeat? Input::UP
        Game_System.se_play $game_data.system.cursor_se
        index -= 1
      end

      @index += @commands.length
      @index %= @commands.length

      @top_row = @index if @index < @top_row
      @top_row = @index - @num_rows + 1 if @index > @top_row + @num_rows - 1

      cycle += 1
      refresh if (@cycle % 20 == 0 || old_index != @index)
    end

    update_cursor_rect
  end

  # Enables or disables a command.
  #
  # @param index command index.
  # @param enabled whether the command is enabled.
  def set_enabled(index, enabled)
    @disabled[index] = enabled
    refresh
  end

  def actor=(actor_id)
    @actor_id = Player.rpg2k3? ? actor_id : 0

    if (@actor_id == 0)
      @commands = [
                   !Data.terms.command_attack.empty? ? Data.terms.command_attack : "Attack",
                   !Data.terms.command_defend.empty? ? Data.terms.command_defend : "Defend",
                   !Data.terms.command_item.empty? ? Data.terms.command_item : "Item",
                   !Data.terms.command_skill.empty? ? Data.terms.command_skill : "Skill",
                  ]
    else
      @commands = Game_Actors.actor(@actor_id).battle_commands.map { |v|
        Data.battlecommands.commands[v].name
      }
    end

    @disabled = Array.new @commands.length
    refresh
  end

  def active=(v)
    @index = v ? 0 : -1
    @top_row = 0
    super active
    refresh
  end

  def update_cursor_rect
    if @index.nil?; self.cursor_rect = Rect.new
    else; self.cursor_rect = Rect.new 0, (@index - @top_row) * 16, contents.width, 16
    end
  end

  def command
    return Data.battlecommands.commands[Game_Actors.actor(@actor_id).battlecommands[@index]] if
      @actor_id > 0

    types = [
             RPG::BattleCommand::Type_attack,
             RPG::BattleCommand::Type_defense,
             RPG::BattleCommand::Type_item,
             RPG::BattleCommand::Type_special
            ]
    command.index = @index + 1
    command.name = @commands[@index]
    command.type = types[@index]
    command
  end

  def skill_subst
    return RPG::Skill::Type_normal if @actor_id == 0

    idx = 4
    for i in 1...Game_Actors.actor(@actor_id).battle_commands[@index]
      idx += 1 if Data.battlecommands.commands[i].type == RPG::BattleCommand::Type_subskill
    end
    idx
  end

  def draw_item(index, color)
    y = 16 * (@index - @top_row)
    return if y < 0 or y + 16 > contents.height
    contents.fill Rect.new(0, y, contents.width, 16), Color.new
    contents.draw_text_2k 2, y + 2, @commands[@index], color
  end
end
