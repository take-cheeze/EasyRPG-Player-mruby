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

# Game_Interpreter_Map class
class Game_Interpreter_Map < Game_Interpreter
  def decode_int(idx)
    v = 0
    begin
      x = @list[@index][idx]
      v  <<= 7
      v = (v << 7) | (x & 0x7f)
      idx += 1
    end while (x & 0x80) != 0
    return v, idx
  end

  def decode_string(idx)
    len, idx = decode_int(idx)
    ret = ''
    for _ in 0...len
      ret << @list[@index][idx]
      idx += 1
    end
    return ret, idx
  end

  def decode_move(idx)
    com = @list[@index]
    ret = {}
    ret[:id] = com
    idx += 1

    case ret[:id]
    when 32, 33
      ret[:parameter_a], idx = decode_int idx
    when 34
      cmd[:parameter_string], idx = decode_string idx
      cmd[:parameter_a], idx = decode_int idx
    when 35
      cmd[:parameter_string], idx = decode_string idx
      cmd[:parameter_a], idx = decode_int idx
      cmd[:parameter_b], idx = decode_int idx
      cmd[:parameter_c], idx = decode_int idx
    end

    return ret, idx
  end

  def end_move_route(route)
    idx = @pending.find_index { |v| v.route == route }
    @pending.delete idx if not idx.nil?
  end

  def execute_command
    return command_end if @index < @list.length

    case @list[@index].code
    when Cmd::Label, Cmd::Loop, Cmd::EndShop, Cmd::EndInn, Cmd::EndBattle, Cmd::EndBranch;
      return true
    when Cmd::Transaction, Cmd::NoTransaction; skip_to Cmd::EndShop
    when Cmd::Stay, Cmd::NoStay; skip_to Cmd::EndInn
    when Cmd::VictoryHandler, Cmd::EscapeHandler, Cmd::DefeatHandler; skip_to Cmd::EndBattle
    when Cmd::ElseBranch; skip_to Cmd::EndBranch
    else; super
    end
  end

  def command_message_option(com)
    Game_Message.background = com[0] == 0
    Game_Message.position = com[1]
    Game_Message.fixed_position = com[2] == 0
    Game_Message.dont_halt = com[3] != 0
    true
  end

  def command_change_exp(com)
    v = operate_value com[2], com[3], com[4]
    actors(com[0], com[1]).each { |actor| actor.change_exp actor.exp + v, com[5] != 0 }
    true
  end

  def command_change_parameters(com)
    v = operate_value com[2], com[4], com[5]
    actors(com[0], com[1]).each { |actor|
      case com[3]
      when 0; actor.base_max_hp = actor.base_max_hp + v
      when 1; actor.base_max_sp = actor.base_max_sp + v
      when 2; actor.base_attack = actor.base_attack + v
      when 3; actor.base_defense = actor.base_defense + v
      when 4; actor.base_spirit = actor.base_spirit + v
      when 5; actor.base_agility = actor.base_agility + v
      end
    }
    true
  end

  def command_change_hero_name(com)
    Game_Actors.actor(com[0]).name = com.string
    true
  end

  def command_change_hero_title(com)
    Game_Actors.actor(com[0]).title = com.string
    true
  end


  def command_change_sprite_association(com)
    Game_Actor.actor(com[0]).set_sprite(com.string, com[1], com[2] != 0)
    $game_player.refresh
    true
  end

  def Game_Interpreter_Map::CommandMemorizeLocation(com)
    player = $game_player
    Game_Variables[com[0]] = Game_Map.map_id
    Game_Variables[com[1]] = player.x
    Game_Variables[com[2]] = player.y
    true
  end

  def Game_Interpreter_Map::CommandRecallToLocation(com)
    player = $game_player
    map_id = Game_Variables[com[0]]
    x = Game_Variables[com[1]]
    y = Game_Variables[com[2]]

    if map_id == Game_Map.map_id
      player.move_to x, y
      return true
    end

    if $game_player.teleporting? or Game_Message.visible
      return false
    end

    $game_player.reserve_teleport map_id, x, y
    @index += 1

    false
  end

  def command_store_terrain_id(com)
    x = value_or_variable com[0], com[1]
    y = value_or_variable com[0], com[2]
    Game_Variables[com[3]] = Game_Map.terrain_tag(x, y)
    true
  end

  def command_store_event_id(com)
    x = value_or_variable(com[0], com[1])
    y = value_or_variable(com[0], com[2])
    events = Game_Map.events_xy(x, y)
    Game_Variables[com[3]] = events.length > 0 ? events[0].id : 0
    true
  end

  def command_memorize_bgm(com)
    Game_System.memorize_bgm()
    true
  end

  def command_play_memorized_bgm(com)
    Game_System.play_memorized_bgm
    true
  end

  def command_change_system_bgm(com)
    Game_System.set_system_bgm(com[0], {
                                 :name => com.string,
                                 :fadein => com[1],
                                 :volume => com[2],
                                 :tempo => com[3],
                                 :balance => com[4],
                               })
    true
  end

  def command_change_system_sfx(com)
    Game_System.set_system_bgm(com[0], {
                                 :name => com.string,
                                 :volume => com[1],
                                 :tempo => com[2],
                                 :balance => com[3],
                               })
    true
  end

  def command_change_save_access(com)
    Game_System.allow_save = com[0] != 0
    true
  end

  def command_change_teleport_access(com)
    Game_System.allow_teleport = com[0] != 0
    true
  end

  def command_change_escape_access(com)
    Game_System.allow_escape = com[0] != 0
    true
  end

  def command_change_main_menu_access(com)
    Game_System.allow_menu = com[0] != 0
    true
  end

  def command_change_actor_face(com)
    actor = Game_Actors.actor com[0]
    if not actor.nil?
      actor.set_face(com.string, com[1])
      return true
    else; return false
    end
  end

  def command_teleport(com)
    # TODO: if in battle return true
    return false if $game_player.teleporting?

    # FIXME: RPG2K3 => facing direction = com[3]

    $game_player.reserve_teleport com[0], com[1], com[2]

    if Game_Message.visible
      Game_Message.visible = false
      Game_Message.full_clear
    end

    $game_player.start_teleport
    index += 1
    false
  end

  def command_erase_screen(com)
    return false if Game_Temp.transition_processing

    Game_Temp.transition_processing = true
    Game_Temp.transition_erase = true

    case com[0]
    when -1; Game_Temp.transition_type = Graphics::TransitionNone
    when 0; Game_Temp.transition_type = Graphics::TransitionFadeOut
    when 1; Game_Temp.transition_type = Graphics::TransitionRandomBlocks
    when 2; Game_Temp.transition_type = Graphics::TransitionRandomBlocksUp
    when 3; Game_Temp.transition_type = Graphics::TransitionRandomBlocksDown
    when 4; Game_Temp.transition_type = Graphics::TransitionBlindClose
    when 5; Game_Temp.transition_type = Graphics::TransitionVerticalStripesOut
    when 6; Game_Temp.transition_type = Graphics::TransitionHorizontalStripesOut
    when 7; Game_Temp.transition_type = Graphics::TransitionBorderToCenterOut
    when 8; Game_Temp.transition_type = Graphics::TransitionCenterToBorderOut
    when 9; Game_Temp.transition_type = Graphics::TransitionScrollUpOut
    when 10; Game_Temp.transition_type = Graphics::TransitionScrollDownOut
    when 11; Game_Temp.transition_type = Graphics::TransitionScrollLeftOut
    when 12; Game_Temp.transition_type = Graphics::TransitionScrollRightOut
    when 13; Game_Temp.transition_type = Graphics::TransitionVerticalDivision
    when 14; Game_Temp.transition_type = Graphics::TransitionHorizontalDivision
    when 15; Game_Temp.transition_type = Graphics::TransitionCrossDivision
    when 16; Game_Temp.transition_type = Graphics::TransitionZoomIn
    when 17; Game_Temp.transition_type = Graphics::TransitionMosaicOut
    when 18; Game_Temp.transition_type = Graphics::TransitionWaveOut
    when 19; Game_Temp.transition_type = Graphics::TransitionErase
    else; Game_Temp.transition_type = Graphics::TransitionNone
    end

    true
  end

  def command_show_screen(com)
    return false if Game_Temp.transition_processing

    Game_Temp.transition_processing = true
    Game_Temp.transition_erase = false

    case com[0]
    when -1; Game_Temp.transition_type = Graphics::TransitionNone
    when 0; Game_Temp.transition_type = Graphics::TransitionFadeIn
    when 1; Game_Temp.transition_type = Graphics::TransitionRandomBlocks
    when 2; Game_Temp.transition_type = Graphics::TransitionRandomBlocksUp
    when 3; Game_Temp.transition_type = Graphics::TransitionRandomBlocksDown
    when 4; Game_Temp.transition_type = Graphics::TransitionBlindOpen
    when 5; Game_Temp.transition_type = Graphics::TransitionVerticalStripesIn
    when 6; Game_Temp.transition_type = Graphics::TransitionHorizontalStripesIn
    when 7; Game_Temp.transition_type = Graphics::TransitionBorderToCenterIn
    when 8; Game_Temp.transition_type = Graphics::TransitionCenterToBorderIn
    when 9; Game_Temp.transition_type = Graphics::TransitionScrollUpIn
    when 10; Game_Temp.transition_type = Graphics::TransitionScrollDownIn
    when 11; Game_Temp.transition_type = Graphics::TransitionScrollLeftIn
    when 12; Game_Temp.transition_type = Graphics::TransitionScrollRightIn
    when 13; Game_Temp.transition_type = Graphics::TransitionVerticalCombine
    when 14; Game_Temp.transition_type = Graphics::TransitionHorizontalCombine
    when 15; Game_Temp.transition_type = Graphics::TransitionCrossCombine
    when 16; Game_Temp.transition_type = Graphics::TransitionZoomOut
    when 17; Game_Temp.transition_type = Graphics::TransitionMosaicIn
    when 18; Game_Temp.transition_type = Graphics::TransitionWaveIn
    when 19; Game_Temp.transition_type = Graphics::TransitionErase
    else; Game_Temp.transition_type = Graphics::TransitionNone
    end

    true
  end

  def command_show_picture(com)
    picture = $game_screen.picture com[0]
    top_trans = com[6]
    speed = com[13]

    # Rpg2k does not support this option
    bottom_trans = Player.rpg2k? ? top_trans : com[14]
    # Rpg2k does not support this option
    bottom_trans = Player.rpg2k? ? top_trans : com[14]

    picture.show com.string
    picture.use_transparent = com[7] > 0
    picture.scrolls = com[4] > 0

    picture.move value_or_variable(com[1], com[2]), value_or_variable(com[1], com[3])
    picture.color com[8], com[9], com[10], com[11]
    picture.magnify com[5]
    picture.transparency top_trans, bottom_trans
    picture.transition 0

    case (com[12])
    when 0; picture.stop_effects
    when 1; picture.rotate speed
    when 2; picture.waver speed
    end

    true
  end

  def command_move_picture(com)
    picture = $game_screen.picture com[0]
    top_trans = com[6]
    speed = com[13]

    # Rpg2k does not support this option
    bottom_trans = Player.rpg2k? ? top_trans : com[14]

    picture.move value_or_variable(com[1], com[2]), value_or_variable(com[1], com[3])
    picture.color com[8], com[9], com[10], com[11]
    picture.magnify com[5]
    picture.transparency(top_trans, bottom_trans)
    picture.transition com[14]

    case (com[12])
    when 0; picture.stop_effects
    when 1; picture.rotate speed
    when 2; picture.waver speed
    end

    setup_wait tenths if com[15] != 0

    true
  end

  def command_erase_picture(com)
    $game_screen.picture(com[0]).erase
    true
  end

  def command_weather_effects(com)
    $game_screen.weather com[0], com[1]
    true
  end

  def CommandChangeSystemGraphics(com)
    Game_System.system_name = com.string
    true
  end

  def CommandChangeScreenTransitions(com)
    fades = [
             [
              Graphics::TransitionFadeOut,
              Graphics::TransitionRandomBlocksUp,
              Graphics::TransitionBorderToCenterOut,
              Graphics::TransitionCenterToBorderOut,
              Graphics::TransitionBlindClose,
              Graphics::TransitionVerticalStripesOut,
              Graphics::TransitionHorizontalStripesOut,
              Graphics::TransitionBorderToCenterOut,
              Graphics::TransitionCenterToBorderOut,
              Graphics::TransitionScrollUpOut,
              Graphics::TransitionScrollDownOut,
              Graphics::TransitionScrollLeftOut,
              Graphics::TransitionScrollRightOut,
              Graphics::TransitionVerticalDivision,
              Graphics::TransitionHorizontalDivision,
              Graphics::TransitionCrossDivision,
              Graphics::TransitionZoomIn,
              Graphics::TransitionMosaicOut,
              Graphics::TransitionWaveOut,
              Graphics::TransitionErase,
              Graphics::TransitionNone,
             ],
             [
              Graphics::TransitionFadeIn,
              Graphics::TransitionRandomBlocksDown,
              Graphics::TransitionBorderToCenterIn,
              Graphics::TransitionCenterToBorderIn,
              Graphics::TransitionBlindOpen,
              Graphics::TransitionVerticalStripesIn,
              Graphics::TransitionHorizontalStripesIn,
              Graphics::TransitionBorderToCenterIn,
              Graphics::TransitionCenterToBorderIn,
              Graphics::TransitionScrollUpIn,
              Graphics::TransitionScrollDownIn,
              Graphics::TransitionScrollLeftIn,
              Graphics::TransitionScrollRightIn,
              Graphics::TransitionVerticalCombine,
              Graphics::TransitionHorizontalCombine,
              Graphics::TransitionCrossCombine,
              Graphics::TransitionZoomOut,
              Graphics::TransitionMosaicIn,
              Graphics::TransitionWaveIn,
              Graphics::TransitionErase,
              Graphics::TransitionNone,
             ]
            ]
    Game_System.set_transition(com[0], fades[com[0] % 2][com[1]])
    true
  end

  def command_change_event_location(com)
    event = character(com[0])
    event.move_to value_or_variable(com[1], com[2]), value_or_variable(com[1], com[3]) if
      not event.nil?
    true
  end

  def command_trade_event_locations(com)
    event1, event2 = character(com[0]), character(com[1])

    if !(event1.nil? or event2.nil?)
      event1.move_to(event1.x, event2.y)
      event2.move_to(event2.x, event2.y)
    end

    true
  end

  def command_timer_operation(com)
    timer_id =  Player.rpg2k3? ? com[5] : 0

    case (com[0])
    when 0; Game_Party.set_timer timer_id, value_or_variable(com[1], com[2])
    when 1; Game_Party.start_timer timer_id, com[3] != 0, com[4] != 0
    when 2; Game_Party.stop_timer timer_id
    else; return false
    end

    true
  end

  def command_change_pbg(com)
    Game_Map.parallax_name = com.string
    Game_Map.set_parallax_scroll(com[0] != 0, com[1] != 0,
                                 com[2] != 0, com[4] != 0,
                                 com[3], com[5])
    true
  end

  def command_jump_to_label(com)
    label_id = com[0]

    for idx in 0...@list.length
      next if @list[idx].code != Cmd::Label or @list[idx][0] != label_id
      @index = idx
      break
    end

    true
  end

  def command_break_loop(com)
    skip_to Cmd::EndLoop, Cmd::EndLoop, 0, com.indent - 1
  end

  def command_end_loop(com)
    indent = com.indent

    idx = @index

    while idx >= 0
      c = @list[idx]
      idx += 1
      next if c.indent > indent
      return false if c.indent < indent
      next if c.code != Cmd::Loop
      @index = idx
      break
    end

    true
  end

  def command_move_event(com)
    event = character com[0]
    if not event.nil?
      route = RPG::MoveRoute.new
      move_freq = com[1]
      route.repeat = com[2] != 0
      route.skippable = com[3] != 0

      idx = 4

      while idx < com.length
        c, idx = decode_move idx
        route.move_commands.push c
      end

      event.force_move_route route, move_freq, self
      @pending.push pending_move_route(route, event)
    end
    true
  end

  def command_open_shop(com)
    case (com[0])
    when 0
      Game_Temp.shop_buys = true
      Game_Temp.shop_sells = true
    when 1
      Game_Temp.shop_buys = true
      Game_Temp.shop_sells = false
    when 2
      Game_Temp.shop_buys = false
      Game_Temp.shop_sells = true
    else; return false
    end

    Game_Temp.shop_type = com[1]
    Game_Temp.shop_handlers = com[2] != 0

    Game_Temp.shop_goods.clear
    for i in 4...com.length; Game_Temp::shop_goods.push com[i]; end

    Game_Temp.shop_transaction = false
    close_message_window
    Game_Temp.shop_calling = true
    self.continuation = Game_Interpreter_Map.method :continuation_open_shop
    return false
  end

  def continuation_open_shop(com)
    unless Game_Temp.shop_handlers
      @index += 1
      return true
    end

    return false unless
      skip_to(Game_Temp.shop_transaction ? Cmd::Transaction : Cmd::NoTransaction, Cmd::EndShop)

    @index += 1
    true
  end

  def command_show_inn(com)
    Game_Temp.inn_price = com[1]
    Game_Temp.inn_handlers = com[2] != 0
    Game_Message.message_waiting = true

    case com[0] # inn type
    when 0
      Game_Message.texts.push('%s %d %s%s' % [Data.term.inn_a_greeting_1,
                                              Game_Temp.inn_price, Data.term.gold,
                                              Data.term.inn_a_greeting_2])
      Game_Message.texts.push Data.term.inn_a_greeting_3
    when 1
      Game_Message.texts.push('%s %d %s%s' % [Data.term.inn_b_greeting_1,
                                              Game_Temp.inn_price, Data.term.gold,
                                              Data.term.inn_b_greeting_2])
      Game_Message.texts.push Data.term.inn_b_greeting_3
    end

    Game_Message.choice_start = Game_Message.texts.length

    case com[0]
    when 0
      Game_Message.texts.push Data.term.inn_a_accept
      Game_Message.texts.push Data.term.inn_a_cancel
    when 1
      Game_Message.texts.push Data.term.inn_b_accept
      Game_Message.texts.push Data.term.inn_b_cancel
    else
      return false
    end

    Game_Message.choice_max = 2
    Game_Message.choice_disabled = nil
    Game_Message.choice_disabled.set 0 if Game_Party.gold < Game_Temp.inn_price

    close_message_window
    Game_Temp.inn_calling = true
    Game_Message.choice_result = 4

    set_continuation { |v| continuation_show_inn v }
    false
  end

  def ContinuationShowInn(com)
    bool inn_stay = Game_Message::choice_result == 0

    Game_Temp::inn_calling = false

    if inn_stay
      Game_Party.gain_gold(-Game_Temp.inn_price)

      unless Game_Temp.inn_handlers
        if inn_stay
          # Full heal
          Game_Party.actors.each { |actor|
            actor.hp = actor.max_hp
            actor.sp = actor.max_sp
            actor.remove_all_states
          }
        end
        @index += 1
        return true
      end
    end

    return false unless skip_to inn_stay ? Cmd::Stay : Cmd::NoStay, Cmd::EndInn
    @index += 1
    true
  end

  def command_enter_hero_name(com)
    Game_Temp.hero_name_id = com[0]
    Game_Temp.hero_name_charset = com[1]
    Game_Temp.hero_name = com[2] != 0 ? Game_Actors.actor(Game_Temp.hero_name_id).name : ''

    close_message_window
    Game_Temp.name_calling = true
    true
  end

  def command_return_to_title_screen(com)
    close_message_window
    Game_Temp.to_title = true
    set_continuation { |v| default_continuation v }
    false
  end

  def command_open_save_menu(com)
    close_message_window
    Game_Temp.save_calling = true
    set_continuation { |v| default_continuation v }
    false
  end

  def command_open_main_menu(com)
    close_message_window
    Game_Temp.menu_calling = true
    set_continuation { |v| default_continuation v }
    false
  end

  def command_enemy_encounter(com)
    Game_Temp.battle_troop_id = value_or_variable com[0], com[1]
    case (com[2])
    when 0
      player = $game_player
      Game_Temp.battle_terrain_id = Game_Map.terrain_tag player.x, player.y
      Game_Temp.battle_background = ''
    when 1
      Game_Temp.battle_terrain_id = 0
      Game_Temp.battle_background = com.string
      Game_Temp.battle_formation = com[7] if Player.rpg2k3?
    when 2
      Game_Temp.battle_terrain_id = com[8]
      Game_Temp.battle_background = ""
    else
      return false
    end
    Game_Temp.battle_escape_mode = com[3]; # disallow, end event processing, custom handler
    Game_Temp.battle_defeat_mode = com[4]; # game over, custom handler
    Game_Temp.battle_first_strike = com[5] != 0

    # normal, initiative, surround, back attack, pincer
    Game_Temp.battle_mode = Player.rpg2k3? ? com[6] : 0

    Game_Temp.battle_result = Game_Temp::BattleVictory

    close_message_window
    Game_Temp.battle_calling = true

    set_continuation { |v| continuation_enemy_encounter v }
    return false
  end

  def continuation_enemy_encounter(com)
    case Game_Temp.battle_result
    when Game_Temp::BattleVictory
      unless skip_to(Cmd::VictoryHandler, Cmd::EndBattle)
        # Was an event battle with no handlers
        @index += 1
        return false
      end
      @index += 1
      return true
    when Game_Temp::BattleEscape
      case Game_Temp.battle_escape_mode
      when 0; return true  # disallowed - shouldn't happen
      when 1; return command_end_event_processing com
      when 2
        return false unless skip_to Cmd::EscapeHandler, Cmd::EndBattle
        @index += 1
        return true
      else; return false
      end
    when Game_Temp::BattleDefeat
      case Game_Temp.battle_defeat_mode
      when 0; return command_game_over com
      when 1
        return false unless skip_to Cmd::DefeatHandler, Cmd::EndBattle
        @index += 1
        return true
      else; return false
      end
    when Game_Temp::BattleAbort
      return false unless skip_to Cmd::EndBattle
      @index += 1
      return true
    else; return false
    end
  end

  def command_teleport_targets(com)
    map_id = com[1]

    if (com[0] != 0)
      Game_Targets.remove_teleport_target map_id
      return true
    end

    x = com[2]
    y = com[3]
    switch_id = com[4] != 0 ? com[5] : nil
    Game_Targets.add_teleport_target(map_id, x, y, switch_id)
    true
  end

  def command_escape_target(com)
    map_id = com[0]
    x = com[1]
    y = com[2]
    switch_id = com[3] != 0 ? com[4] : nil
    Game_Targets.set_escape_target map_id, x, y, switch_id
    true
  end

  def command_sprite_transparency(com)
    $game_player.visible = com[0] != 0
    true
  end

  def command_flash_sprite(com)
    color = Color.new com[1] << 3, com[2] << 3, com[3] << 3, com[4] << 3
    tenths = com[5]
    wait = com[6] > 0
    event = character com[0]

    unless event.nil?
      event.set_flash color, tenths * DEFAULT_FPS / 10
      setup_wait tenths if wait
    end

    true
  end

  def command_erase_event(com)
    return true if @event_id == 0
    Game_Map.events[@event_id].disabled = true
    true
  end

  def command_change_map_tileset(com)
    Game_Map.chipset = com[0]

    scene = Player.find("Map")
    return true if scene.nil?
    scene.spriteset.chipset_updated

    true
  end

  def command_call_event(com)
    return false unless @child_interpreter.nil?

    @child_interpreter = Game_Interpreter_Map.new @depth + 1
    case com[0]
    when 0 # Common Event
      evt_id = com[1]
      @child_interpreter.setup(Data.commonevents[evt_id].event_commands, 0,
                               Data.commonevents[evt_id].index, -2)
      return true
    when 1 # Map Event
      evt_id = com[1]
      event_page = com[2]
    when 2 # Indirect
      evt_id = Game_Variables[com[1]]
      event_page = Game_Variables[com[2]]
    else; return false
    end

    event = character evt_id
    @child_interpreter.setup(event.event.pages[event_page - 1].event_commands,
                             event.id, event.x, event.y) unless event.nil?

    true
  end

  def command_change_encounter_rate(com)
    Game_Map::SetEncounterRate(com[0])
    true
  end

  def command_proceed_with_movement(com); pending.empty?; end

  def CommandPlayMovie(com)
    pos_x = value_or_variable com[0], com[1]
    pos_y = value_or_variable com[0], com[2]
    res_x = com[3]
    res_y = com[4]

    $game_screen.play_movie com.string, pos_x, pos_y, res_x, res_y

    true
  end

  def command_change_battle_commands(com)
    Game_Actors.actor(com[1]).ChangeBattleCommands(com[3] != 0, com[2])
    true
  end

  def command_key_input_proc(com)
    var_id = com[0]
    wait = com[1] != 0

    time = false
    time_id = 0

    check_decision = com[3] != 0
    check_cancel   = com[4] != 0
    check_numbers  = false
    check_arith    = false
    check_shift    = false
    check_down     = false
    check_left     = false
    check_right    = false
    check_up       = false
    result = 0

    if Player.rpg2k?
      check_dir = com[2] != 0
      check_up = check_dir
      check_down = check_dir
      check_left = check_dir
      check_right = check_dir
    elsif Player.rpg2k3?
      param_size = com.length

      # Optimization: If missing -> default value
      check_numbers  = param_size > 5 ? com[5] != 0 : false
      check_arith    = param_size > 6 ? com[6] != 0 : false
      check_shift    = param_size > 9 ? com[9] != 0 : true
      check_down     = param_size > 10 ? com[10] != 0 : true
      check_left     = param_size > 11 ? com[11] != 0 : true
      check_right    = param_size > 12 ? com[12] != 0 : true
      check_up       = param_size > 13 ? com[13] != 0 : true

      if (param_size > 8)
        time_id = com[7]
        time = com[8] != 0
      end
    end

    result = 1 if (check_down && Input().IsTriggered(Input_::DOWN))
    result = 2 if (check_left && Input().IsTriggered(Input_::LEFT))
    result = 3 if (check_right && Input().IsTriggered(Input_::RIGHT))
    result = 4 if (check_up && Input().IsTriggered(Input_::UP))
    result = 5 if (check_decision && Input().IsTriggered(Input_::DECISION))
    result = 6 if (check_cancel && Input().IsTriggered(Input_::CANCEL))
    result = 7 if (check_shift && Input().IsTriggered(Input_::SHIFT))

    if check_numbers
      for i in 0...10
        result = 10 + i if Input.trigger?(Input::N0 + i)
      end
    end

    if check_arith
      for i in 0...5
        result = 20 + i if Input.trigger?(Input::PLUS + i)
      end
    end

    Game_Variables[var_id] = result

    return true unless wait

    @button_timer += 1

    return false if result == 0

    Game_Variables[time_id] = button_timer if time
    @button_timer = 0

    true
  end

  def command_change_vehicle_graphic(com)
    Game_Map.vehicle(com[0]).set_graphic(com.string, com[1])
    true
  end

  def command_enter_exit_vehicle(com)
    $game_player.on_off_vehicle
    true
  end

  def command_set_vehicle_location(com)
    map_id = value_or_variable com[1], com[2]
    x = value_or_variable com[1], com[3]
    y = value_or_variable com[1], com[4]
    Game_Map.vehicle(com[0]).set_position(map_id, x, y)

    true
  end

  def command_tile_substitution(com)
    upper = com[0] != 0
    old_id = com[1]
    new_id = com[2]

    scene = Player.find 'Map'
    return true if scene.nil?

    if upper; scene.spriteset.substitute_up old_id, new_id
    else; scene.spriteset.substitute_down old_id, new_id
    end

    true
  end

  def command_pan_screen(com)
    wait = false

    return !Game_Map.pan_wating? if @active

    case com[0]
    when 0; Game_Map.lock_pan # Lock
    when 1; Game_Map.unlock_pan # Unlock
    when 2; Game_Map.start_pan com[1], com[2], com[3], com[4] != 0 # Pan
    when 3; Game_Map.reset_pan com[3], com[4] != 0 # Reset
    end

    !wait
  end

  def command_simulated_attack(com)
    attack = com[2]
    defence = com[3]
    spirit = com[4]
    var = com[5]

    actors(com[0], com[1]).each { |actor|
      result = attack - (actor.defence * defence) / 400 - (actor.spirit * spirit) / 800
      if (var != 0)
        rperc = var * 5
        rval = rand % (2 * rperc) - rperc
        result += result * rval / 100
      end

      result = [0, result].max
      actor.hp = [0, actor.hp - result].max
      Game_Variables[com[7]] = result if com[6] != 0
    }

    true
  end

  def command_show_battle_animation(com)
    return !$game_screen.battle_animation_waiting? if @active

    evt_id = com[1]
    evt_id = @event_id if (evt_id == Game_Character::CharThisEvent)

    $game_screen.show_battle_animation com[0], evt_id, com[3] > 0

    com[2] > 0 # wait
  end

  def command_change_class(com)
    actor_id = com[1]
    class_id = com[2]
    level1 = com[3] > 0
    show = com[6] > 0

    actor = Game_Actors.actor actor_id

    cur_lvl = actor.level
    cur_exp = actor.exp

    case (stats_mode)
    when 2
      actor.class = class_id
      actor.level = 1
      actor.exp = 0
    when 3; actor.class = class_id
    end

    cur_hp = actor.base_max_hp
    cur_sp = actor.base_max_sp
    cur_atk = actor.base_attack
    cur_def = actor.base_defense
    cur_spi = actor.base_spirit
    cur_agi = actor.base_agility

    case (com[5]) # no change, halve, level 1, current level
    when 1
      cur_hp /= 2
      cur_sp /= 2
      cur_atk /= 2
      cur_def /= 2
      cur_spi /= 2
      cur_agi /= 2
    end

    actor.class = class_id
    if (level1)
      actor.level = 1
      actor.exp = 0
    else
      actor.exp = cur_exp
      actor.level = cur_lvl
    end

    actor.base_max_hp = cur_hp
    actor.base_max_sp = cur_sp
    actor.base_attack = cur_atk
    actor.base_defense = cur_def
    actor.base_spirit = cur_spi
    actor.base_agility = cur_agi

    level = actor.level

    case com[4]
    when 0
    when 1; actor.unlearn_skill actor.skills[0] until actor.skills.empty?
    when 2
      klass = Data.classes[class_id]
      actor.unlearn_skill actor.skills[0] until actor.skills.empty?
      klass.skills.each { |v| if level >= v.level; actor.learn_skill v.skill_id; end }
    end

    if (show && level > cur_lvl)
      # TODO
      # Show message increase level
    end

    true
  end

  def command_halt_all_movement(com)
    @pending.each { |v| v[1].cancel_move_route v[0], self }
    @pending.clear
    true
  end

  def command_conditional_branch(com)
    result = false

    case (com[0])
    when 0 # Switch
      result = Game_Switches[com[1]] == (com[2] == 0)
    when 1 # Variable
      value1 = Game_Variables[com[1]]
      value2 = com[2] == 0 ? com[3] : Game_Variables[com[3]]
      case (com[4])
      when 0; result = (value1 == value2) # Equal to
      when 1; result = (value1 >= value2) # Greater than or equal
      when 2; result = (value1 <= value2) # Less than or equal
      when 3; result = (value1 >  value2) # Greater than
      when 4; result = (value1 <  value2) # Less than
      when 5; result = (value1 != value2) # Different
      end
    when 2 # Timer
      value1 = Game_Party.read_timer Game_Party::Timer1
      value2 = com[1] * DEFAULT_FPS
      case com[2]
      when 0; result = (value1 >= value2)
      when 1; result = (value1 <= value2)
      end
    when 3 # Gold
      case com[2]
      when 0; result = (Game_Party::GetGold() >= com[1]) # Greater than or equal
      when 1; result = (Game_Party::GetGold() <= com[1]) # Less than or equal
      end
    when 4 # Item
      case com[2]
      when 0; result = Game_Party::ItemNumber(com[1]) > 0 # Having
      when 1; result = Game_Party::ItemNumber(com[1]) == 0 # Not having
      end
    when 5
      # Hero
      actor_id = com[1]
      actor = Game_Actors.actor actor_id
      case (com[2])
      when 0
        # Is actor in party
        result = Game_Party.actor_in_party? actor_id
      when 1 # Name
        result = actor.name == com.string
      when 2 # Higher or equal level
        result = actor.level >= com[3]
      when 3 # Higher or equal HP
        result = actor.hp >= com[3]
      when 4 # Is skill learned
        result = actor.skill_learned? com[3]
      when 5 # Equipped object
        result = (
                  (actor.shield_id == com[3]) ||
                  (actor.armor_id == com[3]) ||
                  (actor.helmet_id == com[3]) ||
                  (actor.accessory_id == com[3]) ||
                  (actor.weapon_id == com[3])
                  )
      when 6
        # Has state
        result = actor.has_state com[3]
      end
    when 6
      # Orientation of char
      character = character com[1]
      result = character.direction == com[2] unless character.nil?
    when 7
      # TODO On vehicle
    when 8
      # TODO Key decision initiated this event
    when 9
      # TODO BGM Playing
    when 10
      value1 = Game_Party.read_timer Game_Party::Timer2
      value2 = com[1] * DEFAULT_FPS
      case (com[2])
      when 0; result = (value1 >= value2)
      when 1; result = (value1 <= value2)
      end
    end

    return true if result

    skip_to Cmd::ElseBranch, Cmd::EndBranch
  end
end
