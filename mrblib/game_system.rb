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

module Game_System
  class Target
    attr_reader :map_id, :x, :y, :switch_id

    def initialize(map_id = nil, x = nil, y = nil, switch_id = nil)
      @map_id = map_id
      @x, @y = x, y
      @switch_id = switch_id
    end
  end

  BGM_Battle = 0
  BGM_Victory = 1
  BGM_Inn = 2
  BGM_Skiff = 3
  BGM_Ship = 4
  BGM_Airship = 5
  BGM_GameOver = 6
  BGM_Count = 6

  SFX_Cursor = 0
  SFX_Decision = 1
  SFX_Cancel = 2
  SFX_Buzzer = 3
  SFX_BeginBattle = 4
  SFX_Escape = 5
  SFX_EnemyAttacks = 6
  SFX_EnemyDamage = 7
  SFX_AllyDamage = 8
  SFX_Evasion = 9
  SFX_EnemyKill = 10
  SFX_UseItem = 11
  SFX_Count = 12

  Transition_TeleportErase = 0
  Transition_TeleportShow = 1
  Transition_BeginBattleErase = 2
  Transition_BeginBattleShow = 3
  Transition_EndBattleErase = 4
  Transition_EndBattleShow = 5
  Transition_Count = 6
end

class << Game_System
  def data
    $game_data[:system] ||= {
      :current_music => {}
    }
  end

  # Initializes Game System.
  def init
  end

  # Plays a Music.
  #
  # @param bgm music data.
  def bgm_play(bgm)
    if bgm.name != '(OFF)'
      if bgm.name != data.current_music.name
        Audio.bgm_play bgm.name, bgm.volume, bgm.tempo
      else
        Audio.bgm_volume bgm.volume if bgm.volume != data.current_music.volume
        Audio.bgm_pitch bgm.tempo if bgm.tempo != data.current_music.tempo
      end
    else
      Audio.bgm_stop
    end

    data.current_music = bgm
    Graphics.frame_reset
  end

  # Plays a Sound.
  #
  # @param se sound data.
  def se_play(se)
    if se.class == Fixnum
      se_play system_se(se)
    else
      Audio.se_play se.name, se.volume, se.tempo if se.name != '(OFF)'
    end
  end

  # Gets system graphic name.
  #
  # @return system graphic filename.
  def system_name; data.system || Data.system.system; end

  # Sets the system graphic.
  #
  # @param system_name new system name.
  def system_name=(v); data.graphics_name = v; end

  # Gets the system music.
  #
  # @param which which "context" to set the music for.
  # @return the music.
  def system_bgm(which)
    case which
    when BGM_Battle; return data.battle_music
    when BGM_Victory; return data.battle_end_music
    when BGM_Inn; return data.inn_music
    when BGM_Skiff; return data.boat_music
    when BGM_Ship; return data.ship_music
    when BGM_Airship; return data.airship_music
    when BGM_GameOver; return data.gameover_music
    end
    nil
  end

  # Sets the system music.
  #
  # @param which which "context" to set the music for.
  # @param bgm the music.
  def set_system_bgm(which, bgm)
    case which
    when BGM_Battle; data.battle_music = bgm
    when BGM_Victory; data.battle_end_music = bgm
    when BGM_Inn; data.inn_music = bgm
    when BGM_Skiff; data.boat_music = bgm
    when BGM_Ship; data.ship_music = bgm
    when BGM_Airship; data.airship_music = bgm
    when BGM_GameOver; data.gameover_music = bgm
    end
  end

  SYSTEM_SE_TABLE = [
    :cursor_se, :decision_se, :cancel_se, :buzzer_se,
    :battle_se, :escape_se, :enemy_attack_se, :enemy_damaged_se,
    :actor_damaged_se, :dodge_se, :enemy_death_se, :item_se]

  # Gets the system sound effects.
  #
  # @param which which "context" to set the music for.
  # @return the sound.
  def system_se(which)
    sym = SYSTEM_SE_TABLE[which]
    raise "invalid system se type" if sym.nil?
    data[sym] || Data.system[sym]
  end

  # Sets a system sound effect.
  #
  # @param which which "context" to set the effect for.
  # @param sfx the sound effect.
  def set_system_se(which, sfx)
    sym = SYSTEM_SE_TABLE[which]
    raise "invalid system se type" if sym.nil?
    data[sym] = sfx
  end

  # Gets the system transitions.
  #
  # @param which which "context" to get the transition for.
  # @return the transition.
  def transition(which)
    case which
    when Transition_TeleportErase; return data.transition_out
    when Transition_TeleportShow; return data.transition_in
    when Transition_BeginBattleErase; return data.battle_start_fadeout
    when Transition_BeginBattleShow; return data.battle_start_fadein
    when Transition_EndnBattleErase; return data.battle_end_fadeout
    when Transition_EndBattleShow; return data.battle_end_fadein
    end
    nil
  end

  # Sets the system transitions.
  #
  # @param which which "context" to set the transition for.
  # @param transition the transition.
  def set_transition(which, transition)
    case which
    when Transition_TeleportErase; data.transition_out = transition
    when Transition_TeleportShow; data.transition_in = transition
    when Transition_BeginBattleErase; data.battle_start_fadeout = transition
    when Transition_BeginBattleShow; data.battle_start_fadein = transition
    when Transition_EndnBattleErase; data.battle_end_fadeout = transition
    when Transition_EndBattleShow; data.battle_end_fadein = transition
    end
  end

  def allow_teleport?; data.teleport_allowed; end
  def allow_teleport(v); data.teleport_allowed = v; end

  def allow_escape?; data.escape_allowed; end
  def allow_escape(v); data.escape_allowed = v; end

  def allow_save?; data.save_allowed; end
  def allow_save(v); data.save_allowed = v; end

  def allow_menu?; data.menu_allowed; end
  def allow_menu(v); data.menu_allowed = v; end

  def save_count; data.save_count; end

  def current_bgm; data.current_music; end
  def memorize_bgm; data.stored_music = data.current_music.dup; end
  def play_memorized_bgm; bgm_play data.stored_music; end
end
