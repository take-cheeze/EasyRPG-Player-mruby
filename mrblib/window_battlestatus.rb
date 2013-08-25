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
        Game_System.se_play $game_data.system.cursor_se
        for i in 1...num_actors
          new_index = (@index + i) % num_actors
          if Game_Battle.ally(new_index).ready?
            @index = new_index
            break
          end
        end
      end
      if Input.repeat? Input::UP
        Game_System.se_play $game_data.system.cursor_se
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
    contents.stretch_blit(Rect.new(cx + 16, cy, 25, 16), system2,
                          Rect.new(16, gauge_y, 16, 16), 255)
    contents.blit(cx + 16 + 25, cy, system2, Rect.new(32, gauge_y, 16, 16), 255)
    contents.stretch_blit(Rect.new(cx + 16, cy, gauge_w, 16), system2,
                          Rect.new(full ? 64 : 48, gauge_y, 16, 16), 255)
  end
end
