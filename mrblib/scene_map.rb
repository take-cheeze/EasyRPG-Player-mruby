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

# Scene Map class.
class Scene_Map < Scene
  # Constructor.
  def initialize; super 'Map'; end

  def dispose
    $game_screen.reset
  end

  def start
    @spriteset = Spriteset_Map.new
    @message_window = Window_Message.new 0, 240 - 80, 320, 80
    $game_screen.reset
    Graphics.frame_reset
  end

  def transition_in
    super
    Graphics.transition_2k Data.system.transition_in, 12
  end

  def transition_out
    super
    Graphics.transition_2k Data.system.transition_in, 12, true
  end

  def update
    Game_Map.interpreter.update

    Game_Party.update_timers

    Game_Map.update
    $game_player.update
    $game_screen.update
    @spriteset.update
    @message_window.update

    update_teleport_player

    if Game_Temp.gameover
      Game_Temp.gameover = false
      Scene.push Scene_Gameover.new
    end

    if Game_Temp.to_title
      Game_Temp.to_title = false
      Scene.pop_until 'Title'
    end

    return if Game_Message.visible

    # ESC-Menu calling
    if Input.trigger? Input::CANCEL
      # return if Game_Map.interpreter.running?
      # $game_system.menu_disabled

      Game_Temp.menu_calling = true
      Game_Temp.menu_beep = true
    end

    if !$game_player.moving?
      if Game_Temp.menu_calling
        call_menu
        return
      end

      if Game_Temp.name_calling
        Game_Temp.name_calling = false
        Scene.push Scene_Name.new
        return
      end

      if Game_Temp.shop_calling
        Game_Temp.shop_calling = false
        Scene.push Scene_Shop.new
        return
      end

      if Game_Temp.save_calling
        Game_Temp.save_calling = false
        Scene.push Scene_Save.new
        return
      end

      if Game_Temp.battle_calling
        Game_Temp.battle_calling = false
        Scene.push Scene_Battle.new
        return
      end

      if Game_Temp.transition_processing
        Game_Temp.transition_processing = false

        Graphics.transition_2k Game_Temp.transition_type, 32, Game_Temp.transition_erase
      end
    end
  end

  # Scene calling stuff.

  def call_menu
    Game_Temp.menu_calling = false
    if Game_Temp.menu_beep
      Game_System.se_play Game_System::SFX_Decision
      Game_Temp.menu_beep = false
    end

    # TODO: $game_player.straighten

    Scene.push Scene_Menu.new
  end

  def call_debug
    # TODO
  end

  def update_teleport_player
    return if !$game_player.teleporting?

    transition_out
    $game_player.perform_teleport
    Game_Map.autoplay
    @spriteset = Spriteset_Map.new
    Game_Map.update
    transition_in

    Input.update
  end
end
