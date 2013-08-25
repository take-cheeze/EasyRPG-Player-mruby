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

# Game_Interpreter class
class Game_Interpreter
  def initialize(_depth = 0, _main_flag = false)
    @depth = depth
    @main_flag = _main_flag
    @active = false

    Output.warning "Too many events calls (over 9000)" if depth > 100

    clear
  end

  def clear
    @map_id = 0                   # map ID when starting up
    @event_id = 0                 # event ID
    # Game_Message.message_waiting = false  # waiting for message to end
    @move_route_waiting = false   # waiting for move completion
    @button_input_variable_id = 0  # button input variable ID
    @wait_count = 0               # wait count
    @child_interpreter = nil      # child interpreter for common events, etc
    @continuation = nil           # function to execute to resume command
    @button_timer = 0
  end

  def setup(list, id, dbg_x = nil, dbg_y = nil)
    clear

    @map_id = Game_Map.map_id
    @event_id = @id
    @list = list

    @debug_x, @debug_y = dbg_x, dbg_y

    @index = 0

    cancel_menu_call
  end

  def running?; not @list.empty?; end

  def update
    # 10000 based on: https://gist.github.com/4406621
    for loop_count in 0...10000
      # If map is different than event startup time
      # set event_id to 0
      event_id = 0 if Game_Map::map_id != map_id

      # If there's any active child interpreter, update it
      if @child_interpreter
        @child_interpreter.update
        @child_interpreter = nil if not @child_interpreter.running?
        return if @child_interpreter # If child interpreter still exists
      end

      return if Game_Message.message_waiting

      # If waiting for a move to end
      if @move_route_waiting
        return if $game_player.move_route_forcing
        return if not Game_Map.events.find { |v| v.move_route_forcing }.nil?
        @move_route_waiting = false
      end

      if @button_input_variable_id > 0
        input_button
        return
      end

      if @wait_count > 0
        @wait_count -= 1
        return
      end

      return if not Game_Temp.forcing_battler.nil?

      return if # Game_Temp::battle_calling ||
        Game_Temp::shop_calling ||
        # Game_Temp::inn_calling ||
        Game_Temp::name_calling ||
        Game_Temp::menu_calling ||
        Game_Temp::save_calling ||
        Game_Temp::to_title ||
        Game_Temp::gameover

      unless @continuation.nil?
        result = @continuation.call @list[@index]
        @continuation = nil
        if result; next
        else; return
        end
      end

      if @list.empty?
        Game_Map.refresh if
          !$game_player.teleporting? and main_flag and Game_Map.need_refresh?

        return if @list.empty?
      end

      if not execute_command
        close_message_window
        @active = true
        return
      end

      @active = false

      # FIXME?
      # After calling SkipTo this index++ will skip execution of e.g. END.
      # This causes a different timing because loop_count reaches 10000
      # faster then Player does.
      # No idea if any game depends on this special case.
      @index += 1
    end

    # Executed Events Count exceeded (10000)
    @active = true
    Output.debug("Event %d exceeded execution limit" % @event_id)
    close_message_window
  end

  def setup_starting_event(ev)
    if Game_Temp::common_event_id > 0
      setup Data.commonevents[Game_Temp.common_event_id].event_commands, 0
      Game_Temp.common_event_id = 0
      return
    end

    ev.clear_starting
    setup ev.list, ev.id, ev.x, ev.y

    for i in Data.commoneventss
      if i.trigger == RPG::EventPage::Trigger_auto_start
        setup i.event_commands, 0 if i.switch_flag ? Game_Switches[i.switch_id] : true
        break
      end
    end
  end

  def setup_starting_event(ev)
    setup ev.list, 0, ev.index, -2
  end

  def input_button
    n = [ Input::UP, Input::DOWN, Input::LEFT, Input::RIGHT,
          Input::DECISION, Input::CANCEL, Input::SHIFT
        ].find { |v| Input.trigger? v }

    # If a button was pressed
    if not n.nil?
      # Set variable
      Game_Variables[@button_input_variable_id] = n
      Game_Map.need_refresh = true
      @button_input_variable_id = 0
    end
  end

  def setup_choices(choices)
    Game_Message.choice_start = Game_Message.texts.length
    Game_Message.choice_max = choices.length
    Game_Message.choice_disabled = nil

    choices.each { |v| Game_Message.texts.push v }
    set_continuation { |v| continuation_choices v }
  end

  CommandTable = {}
  Cmd.constants.each { |v|
    CommandTable[Cmd.const_get v] = ('command' + v.to_s.bytes.reduce('') { |tmp, c|
                                       tmp += '_' if 'A'.bytes[0] <= c and c <= 'Z'.bytes[0]
                                       tmp += c.chr.downcase
                                     }).to_sym
  }

  def execute_command
    com = @list[@index]
    case com.code
    when Cmd::ShowChoiceOption; return skip_to(Cmd::ShowChoiceEnd)
    when Cmd::ShowChoiceEnd; return true
    when Cmd::Comment, Cmd::Comment_2; return true
    else
      return send CommandTable[com.code], com if CommandTable.key? com.code
    end
    true
  end

  def end_move_route(route)
    # This will only ever be called on Game_Interpreter_Map instances
  end

  def max_size; Player.rpg2k3? ? 9999999 : 999999; end
  def min_size; -max_size; end

  # Gets strings for choice selection.
  # This is just a helper (private) method
  # to avoid repeating code.
  def strings
    # Let's find the choices
    index_temp = @index + 1
    current_indent = @list[index_temp].indent
    s_choices = []

    while index_temp < @list.length
      if ( (@list[index_temp].code == Cmd::ShowChoiceOption) && (list[index_temp].indent == current_indent) )
        # Choice found
        s_choices.push_back(list[index_temp].string)
      end
      # If found end of show choice command
      if ( ( (@list[index_temp].code == Cmd::ShowChoiceEnd) && (@list[index_temp].indent == current_indent) ) ||
           # Or found Cancel branch
           ( (@list[index_temp].code == Cmd::ShowChoiceOption) && (@list[index_temp].indent == current_indent) &&
             (@list[index_temp].string == "") ) )
        break
      end
      # Move on to the next command
      index_temp += 1
    end
    s_choices
  end


  # Calculates operated value.
  #
  # @param operation operation (increase: 0, decrease: 1).
  # @param operand_type operand type (0: set, 1: variable).
  # @param operand operand (number or var ID).
  def operate_value(operation, operand_type, operand)
    value = value_or_variable operand_type, operand
    operation == 1 ? -value : value
  end

  def character(id)
    ch = Game_Character.character id, @event_id
    Output.warning "Unkown event with id %d" % @event_id if ch.nil?
    ch
  end

  def skip_to(code, code2 = nil, min_indent = nil, max_indent = nil)
    code2 = code if code2.nil?
    min_indent = @list[@index].indent if min_indent.nil?
    max_indent = @list[@index].indent if max_inden.nil?

    for i in @index...@list.length
      return false if @list[i].indent < min_indent

      next if @list[i].indent > max_indent or
        (@list[i].code != code && @list[i].code != code2)

      index = i
      return true
    end

    false
  end

  def set_continuation(&func); @continuation = func; end

  def cancel_menu_call
    # TODO
  end

  # Sets up a wait (and closes the message box)
  def setup_wait(duration)
    close_message_window
    # 0.0 waits 1 frame
    @wait_count = duration == 0 ? 1 : duration * DEFAULT_FPS / 10
  end

  # Calculates list of actors.
  #
  # @param mode 0: party, 1: specific actor, 2: actor referenced by variable.
  # @param id actor ID (mode = 1) or variable ID (mode = 2).
  def actors(mode, id)
    ret = []
    case mode
    when 0; ret = Game_Party.actors
    when 1; ret.push Game_Actors.actor(id)
    when 2; ret.push Game_Actors.actor(Game_Variables[id])
    else; raise "invalid mode %d" % mode
    end
    ret
  end

  def value_or_variable(mode, val)
    case mode
    when 0; return val
    when 1; return Game_Variables[val]
    else
      raise "invalid move %d" % mode
    end
  end

  # Closes the message window.
  def close_message_window
    Game_Message.full_clear if Game_Message.visible
    Game_Message.visible = false
  end

  def command_show_message(com)
    # If there's a text already, return immediately
    return false if not Game_Message.texts.empty?

    line_count = 0
    Game_Message.message_waiting = true

    # Set first line
    Game_Message.texts.push com.string
    line_count += 1

    while true
      # If next event command is the following parts of the message
      if @index < @list.length - 1 && @list[@index + 1].code == Cmd::ShowMessage_2
        # Add second (another) line
        line_count += 1
        Game_Message.texts.push @list[@index + 1].string
      else
        # If next event command is show choices
        s_choices = []
        if (@index < @list.length - 1) && (@list[@index + 1].code == Cmd::ShowChoice)
          s_choices = strings

          # If choices fit on screen
          if s_choices.length <= (4 - line_count)
            @index += 1
            Game_Message.choice_start = line_count
            Game_Message.choice_cancel_type = @list[@index][0]
            setup_choices s_choices
          end
        elsif (@index < @list.length - 1) && @list[@index + 1].code == Cmd::InputNumber
          # If next event command is input number
          # If input number fits on screen
          if (line_count < 4)
            @index += 1
            Game_Message.num_input_start = line_count
            Game_Message.num_input_digits_max = @list[@index][0]
            Game_Message.num_input_variable_id = @list[@index][1]
          end
        end

        return true
      end
      @index += 1
    end

    false
  end

  def comand_change_face_graphics(com)
    Game_Message.face_name = com.string
    Game_Message.face_index = com[0]
    Game_Message.face_left_position = com[1] == 0
    Game_Message.face_flipped = com[2] != 0
    true
  end

  def command_show_choices(com)
    return false if (!Game_Message::texts.empty())

    Game_Message.message_waiting = true

    # Choices setup
    Game_Message.choice_cancel_type = com[0]
    setup_choices strings

    true
  end

  def command_input_number(com)
    return false if Game_Message.texts.empty?
    Game_Message.message_waiting = true
    Game_Message.num_input_start = 0
    Game_Message.num_input_variable_id = com[1]
    Game_Message.num_input_digits_max = com[0]
    true
  end

  def command_control_variables(com)
    actor = nil, character = nil

    case com[4]
    when 0; value = com[5] # Constant
    when 1; value = Game_Variables[com[5]] # Var A ops B
    when 2
      # Number of var A ops B
      value = Game_Variables[Game_Variables[com[5]]]
    when 3
      # Random between range
      a = [com[5], com[6]].max
      b = [com[5], com[6]].min
      value = rand() % (a-b+1)+b
    when 4
      # Items
      case (com[6])
      when 0; value = Game_Party.item_number(com[5]) # Number of items posessed
      when 1; value = Game_Party.item_number(com[5], true) # How often the item is equipped
      end

    when 5
      # Hero
      actor = Game_Actors.actor(com[5])
      if (not actor.nil?)
        case com[6]
        when 0; value = actor.level # Level
        when 1; value = actor.exp # Experience
        when 2; value = actor.hp # Current HP
        when 3; value = actor.sp # Current SP
        when 4; value = actor.max_hp # Max HP
        when 5; value = actor.max_sp # Max MP
        when 6; value = actor.attack # Attack
        when 7; value = actor.defence # Defence
        when 8; value = actor.spirit # Spirit
        when 9; value = actor.agility # Agility
        when 10; value = actor.equipment 0 # Weapon
        when 11; value = actor.equipment 1 # Shield
        when 12; value = actor.equipment 2 # Armor
        when 13; value = actor.equipment 3 # Helmet
        when 14; value = actor.equipment 4 # Accessory
        end
      end

    when 6
      # Characters
      if com[6] != 0
        ch = character com[5]
      else
        # Special case for Player Map ID
        ch = nil
        value = Game_Map.map_id
      end

      # Other cases
      if not ch.nil?
        case com[6]
        when 1; value = ch.x # x coordinate
        when 2; value = ch.y # y coordinate
        when 3; value = ch.direction # direction
        when 4; value = ch.screen_x # screen x
        when 5; value = ch.screen_y # screen y
        end
      end
    when 7
      # More
      case (com[5])
      when 0; value = Game_Party.gold # gold
      when 1; value = Game_Party.read_timer(Game_Party::Timer1)
      when 2; value = Game_Party.actors.length # Number of heroes in party
      when 3; value = Game_System.save_count # Number of saves
      when 4; value = Game_Party.battle_count # Number of battles
      when 5; value = Game_Party.win_count # Number of wins
      when 6; value = Game_Party.defeat_count # Number of defeats
      when 7; value = Game_Party.run_count # Number of escapes (aka run away)
      when 8; value = 0 # TODO: MIDI play position
      when 9; value = Game_Party.read_timer(Game_Party::Timer2)
      end
    end

    case (com[0])
    when 0, 1
      # Single and Var range
      for i in com[1]..com[2]
        case (com[3])
        when 0; Game_Variables[i] = value # Assignement
        when 1; Game_Variables[i] += value # Addition
        when 2; Game_Variables[i] -= value # Subtraction
        when 3; Game_Variables[i] *= value # Multiplication
        when 4; Game_Variables[i] /= value if value != 0 # Division
        when 5; value != 0 ? Game_Variables[i] %= value : Game_Variables[i] = 0 # Module
        end
        Game_Variables[i] = [min_size, [Game_Variables[i], max_size].min].max
      end
    when 2
      case (com[3])
      when 0; Game_Variables[com[1]] = value # Assignement
      when 1; Game_Variables[com[1]] += value # Addition
      when 2; Game_Variables[com[1]] -= value # Subtraction
      when 3; Game_Variables[com[1]] *= value # Multiplication
      when 4; Game_Variables[com[1]] /= value if value != 0 # Division
      when 5; Game_Variables[com[1]] %= value if (value != 0) # Module
      end
      Game_Variables[com[1]] = [min_size, [Game_Variables[com[1]], max_size].min].max
    end

    Game_Map.need_refresh = true
    true
  end

  def command_change_gold(com)
    Game_Party.gain_gold operate_value(com[0], com[1], com[2])
    true
  end

  def command_change_items(com)
    value = operate_value com[0], com[3], com[4]

    if com[0] == 1; return true if value > 0
    else; return true if value < 0
    end

    Game_Party.gain_item value_or_variable(com[1], com[2]), value

    Game_Map.need_refresh = true
    true
  end

  def command_change_party_member(com)
    id = value_or_variable com[1], com[2]
    actor = Game_Actors.actor id
    if not actor.nil?
      if com[0] == 0
        Game_Party.add_actor id
      else
        Game_Party.remove_actor id
      end
    end

    Game_Map.need_refresh = true
    true
  end

  def command_change_level(com)
    value = operate_value com[2], com[3], com[4]
    actors(com[0], com[1]).each { |v|
      v.change_level v.level + value, com[5] != 0
    }
  end

  def command_change_skills(com)
    skill_id = value_or_variable com[3], com[4]

    actors(com[0], com[1]).each { |v|
      if com[2] != 0
        v.unlearn_skill skill_id
      else
        v.learn_skill skill_id
      end
    }
  end

  def command_change_equipment(com)
    case com.paramters[2]
    when 0
      item_id = value_or_variable com[3], com[4]
      case Data.items[item_id].type
      when RPG::Item::Type_weapon, RPG::Item::Type_shield,
        RPG::Item::Type_armor, RPG::Item::Type_helmet,
        RPG::Item::Type_accessory
        slot = type - 1
      else; return true
      end
    when 1
      item_id = 0
      slot = com.paramters[3]
    else
      return false
    end

    actors(com.paramters[0], com[1]).each { |v|
      v.change_equipment slot, item_id
    }
    true
  end

  def command_change_hp(com)
    amount = value_or_variable com[3], com[4]
    amount = -amount if com[2] != 0

    ko = com[5] != 0

    actors(com[0], com.paramters[1]).each { |v|
      v.hp = [ko ? 0 : 1, v.hp + amount].max
    }
    true
  end

  def command_change_sp(com)
    amount = value_or_variable com[3], com[4]
    amount = -amount if com[2] != 0

    actors(com[0], com[1]).each { |v|
      v.sp = [0, v.sp + amount].max
    }

    true
  end

  def comannd_change_condition(com)
    remove = com[2] != 0
    state_id = com[3]

    actors(com[0], com[1]).each { |v|
      if remove; v.remove_state state_id
      else v.add_state state_id
      end
    }

    true
  end

  def command_full_heal(com)
    actors(com[0], com[1]).each { |v|
      actor.hp = actor.max_hp
      actor.sp = actor.max_sp
      actor.remove_all_states
    }
    true
  end

  def command_tint_screen(com)
    screen = $game_screen
    r = com[0]
    g = com[1]
    b = com[2]
    s = com[3]
    tenths = com[4]
    wait = com[5] != 0

    screen.tint_screen r, g, b, s, tenths
    setup_wait tenths if wait

    true
  end

  def command_flash_screen(com)
    screen = $game_screen
    r = com[0]
    g = com[1]
    b = com[2]
    s = com[3]
    tenths = com[4]
    wait = com[5] != 0

    if Player.rpg2k3?
      case com[6]
      when 0
        screen.flash_once r, g, b, s, tenths
        setup_wait tenths if wait
      when 1; screen.flash_begin r, g, b, s, tenths
      when 2; screen.flash_end
      end
    else
      screen.flash_once(r, g, b, s, tenths)
      setup_wait tenths if wait
    end

    true
  end

  def command_shake_screen(com)
    screen = $game_screen
    strength = com[0]
    speed = com[1]
    tenths = com[2]
    wait = com[3] != 0

    if Player.rpg2k?
      screen.shake_once strength, speed, tenths
      setup_wait tenths if wait
    else
      case com[4]
      when 0
        screen.shake_once strength, speed, tenths
        setup_wait tenths if wait
      when 1; screen.shake_begin strength, speed
      when 2; screen.shake_end()
      end
    end

    true
  end

  def command_wait(com)
    if Player.rpg2k? or com[1] == 0
      setup_wait com[0]
      return true
    else
      return Input.any_trigger?
    end
  end

  def command_play_bgm(com)
    Game_System.play_bgm({ :name => com.string,
                           :fadein => com[0],
                           :volume => com[1],
                           :tempo => com[2],
                           :balance => com[3] })
    true
  end

  def command_fadeout_bgm(com)
    Audio.bgm_fade com[0]
    true
  end

  def command_play_sound(com)
    Game_System.se_play({ :name => com.string,
                          :volume => com[0],
                          :tempo => com[1],
                          :balance => com[2] })
    true
  end

  def command_end_event_processing(com)
    @index = @list.length
    true
  end

  def command_game_over(com)
    close_message_window
    Game_Temp.gameover = true
    set_continuation { |v| default_continuation v }
    false
  end

  def command_control_switches(com)
    case com[0]
    when 0, 1
      for i in com[1]..com[2]
        Game_Switches[i] = com[3] != 2 ? com[3] == 0 : !Game_Switches[i]
      end
    when 2
      Game_Switches[Game_Variables[com[1]]] =
        com[3] != 2 ? com[3] == 0 : !Game_Switches[Game_Variables[com[1]]]
    else; return false
    end

    Game_Map.need_refresh = true
    true
  end

  def command_end
    close_message_window
    @list.clear
    Game_Map.events[@event_id].unlock if main_flag and @event_id > 0
  end

  def default_continuation(com)
    @index += 1
    true
  end
  def continuation_choices(com)
    indent = com.indent
    begin
      return false if not skip_to Cmd::ShowChoiceOption, Cmd::ShowChoiceEnd, indent, indent

      which = @list[@index].parameters[0]
      @index += 1
      return false if which > Game_Message.choice_result
    end while which < Game_Message.choice_result
    true
  end
  def continuation_open_shop(com); true; end
  def continuation_show_inn(com); true; end
  def continuation_enemy_encounter(com); true; end
end
