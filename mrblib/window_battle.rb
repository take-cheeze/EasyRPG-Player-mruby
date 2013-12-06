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
        Game_System.se_play Game_System::SFX_Cursor
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
                   !Data.term.command_attack.empty? ? Data.term.command_attack : "Attack",
                   !Data.term.command_defend.empty? ? Data.term.command_defend : "Defend",
                   !Data.term.command_item.empty? ? Data.term.command_item : "Item",
                   !Data.term.command_skill.empty? ? Data.term.command_skill : "Skill",
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

# Window BattleItem class.
# Displays all items of the party for use in battle.
class Window_BattleItem < Window_Item
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @actor_id = 0
  end

  attr_writer :index

  # Checks if item should be enabled.
  #
  # @param item_id item to check.
  def check_enable(item_id)
    item = Data.items[item_id]

    case item.type
    when RPG::Item::Type_normal; return false
    when RPG::Item::Type_weapon, RPG::Item::Type_shield, RPG::Item::Type_armor, RPG::Item::Type_helmet, RPG::Item::Type_accessory
      return item.use_skill && can_use_item?(item) && can_use_skill?(item.skill_id)
    when RPG::Item::Type_medicine
      return can_use_item?(item) && !item.occasion_field1 && (!item.ko_only || Game_Battle.have_corpse)
    when RPG::Item::Type_book, RPG::Item::Type_material; return false
    when RPG::Item::Type_special; return can_use_item?(item) && can_use_skill?(item.skill_id)
    when RPG::Item::Type_switch; return item.occasion_battle
    else; return false
    end
  end

  def can_use_item?(item)
    return false if @actor_id <= 0
    return true if actor_id >= item.actor_set.length || item.actor_set[@actor_id]
    return false if Player.rpg2k?
    actor = Data.actor[@actor_id]
    return false if actor.class_id < 0
    return true if actor.class_id >= item.class_set.length || item.class_set[actor.class_id]
    false
  end

  def can_use_skill?(skill_id)
    skill = Data.skills[skill_id]
    skill.type != RPG::Skill::Type_switch or skill.occasion_battle
  end
end

# Window_BattleOption class.
class Window_BattleOption < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih

    self.contents = Bitmap.new iw - 16, ih - 16

    # @commands = [Data.term.battle_fight, Data.term.battle_auto, Data.term.battle_escape]
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
    #  Font::SystemColor color = (i == 2 && Game_Temp::battle_escape_mode == 0)
    #    ? Font::ColorDisabled
    #    : Font::ColorDefault
    #  DrawItem(i, color)
    #end
  end

  # Updates the window state.
  def update
    super

    if @active && @num_commands >= 0 && (not @index.nil?)
      if Input.repeat? Input::DOWN
        Game_System.se_play Game_System::SFX_Cursor
        @index += 1
      end

      if Input.repeat? Input::UP
        Game_System.se_play Game_System::SFX_Cursor
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

# Window_BattleSkill class.
class Window_BattleSkill < Window_Skill
  # Sets the actor whose skills are displayed.
  #
  # @param id ID of the actor.
  def subst=(id)
    @subst = id
    refresh
  end

  # Checks if the skill should be in the list.
  #
  # @param skill_id skill to check.
  def check_include(skill_id)
    type = Data.skills[skill_id]
    @subst == RPG::Skill::Type_normal ? type < 4 : @subst == type
  end

  # Chechs if skill should be enabled.
  #
  # @param skill_id skill to check.
  def check_enable(skill_id)
    skill = Data.skills[skill_id]
    skill.type == RPG::Skill::Type_switch ? skill.occasion_battle : true
  end
end

# Window BattleStatus Class.
# Displays the party battle status.
class Window_BattleStatus < Window_Base
  # Constructor.
  def initialize
    super 0, 172, 244, 68
    self.border_x = 4
    self.border_y = 4
    self.contents = Bitmap.new width - 8, height - 8
    @index = nil

    refresh
  end

  # Renders the current status on the window.
  def refresh
    contents.clear
    Game_Battle.allies.each_with_index { |v,i|
      y = i * 15
      draw_actor_name v.game_actor, 4, y
      draw_actor_state v.game_actor, 80, y
      draw_actor_hp v.game_actor, 136, y, true
      # draw_gauge v.game_actor, i, 192, y
      draw_actor_sp v.game_actor, 202, y, false
    }
  end

  # Updates the window state.
  def update
    super

    num_actors = Game_Battle.allies.length
    #for (int i = 0; i < num_actors; i++)
    #  RefreshGauge(i);

    if @active && @index >= 0
      if Input.repeat? Input::DOWN
        Game_System.se_play Game_System::SFX_Cursor
        for i in 1...num_actors
          new_index = (@index + i) % num_actors
          if Game_Battle.ally(new_index).ready?
            @index = new_index
            break
          end
        end
      end
      if Input.repeat? Input::UP
        Game_System.se_play Game_System::SFX_Cursor
        for i in (num_actors - 1)...0
          new_index = (@index + i) % num_actors
          if Game_Battle.ally(new_index).ready?
            index = new_index
            break
          end
        end
      end
    end

    choose_active_character

    update_cursor_rect
  end

  # Sets the active character.
  #
  # @param index character index (0..3).
  #              Returns -1 if no character is ready. FIXME
  def active_character=(v)
    @index = v
    refresh
  end

  # Gets the active character.
  #
  # @return character index (0..3).
  def active_character; @index; end

  # Selects an active character if one is ready.
  def choose_active_character
    num_actors = Game_Battle.allies.length
    old_index = @index.nil? ? 0 : @index
    @index = nil

    for i in 0...num_actors
      new_index = (old_index + i) % num_actors
      if Game_Battle.ally(new_index).ready?
        @index = new_index
        break
      end
    end

    update_cursor_rect if @index != old_index
  end

  # Updates the cursor rectangle.
  def update_cursor_rect
    if index.nil?; self.cursor_rect = Rect.new
    else self.cursor_rect = Rect.new 0, @index * 15, contents.width, 16
    end
  end

  # Redraws a character's time gauge.
  #
  # @param i character index (0..3).
  def refresh_gauge(i)
    y = i * 15
    contents.fill Rect.new(192, y, 44, 15), Color.new
    actor = Game_Battle.allies[i].game_actor
    # draw_gauge actor, i, 192, y
    draw_actor_sp actor, 202, y, false
  end

  # Draws a character's time gauge.
  #
  # @param actor actor.
  # @param idx character index (0..3).
  # @param cx x coordinate.
  # @param cy y coordinate.
  def draw_gauge(actor, idx, cx, cy)
    system2 = Cache.system2 Data.system.system2_name

    ally = Game_Battle.ally idx
    full = ally.ready?
    gauge_w = ally.gauge * 25 / Game_Battle.gauge_full
    speed = 2
    gauge_y = 32 + speed * 16

    contents.blit(cx + 0, cy, system2, Rect.new(0, gauge_y, 16, 16), 255)
    contents.stretch_blt(Rect.new(cx + 16, cy, 25, 16), system2,
                          Rect.new(16, gauge_y, 16, 16), 255)
    contents.blit(cx + 16 + 25, cy, system2, Rect.new(32, gauge_y, 16, 16), 255)
    contents.stretch_blt(Rect.new(cx + 16, cy, gauge_w, 16), system2,
                          Rect.new(full ? 64 : 48, gauge_y, 16, 16), 255)
  end
end
