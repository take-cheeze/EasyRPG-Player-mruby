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

# Game_Vehicle class.
class Game_Vehicle < Game_Character
	MAX_ALTITUDE = 32 # the airship flies at

  Boat = 0
  Ship = 1
  Airship = 2

  def initialize(type)
    @type = type
    @altitude = 0
    @driving = false
    @direction = RPG::EventPage::Direction_left
    @walk_animation = false
    load_system_settings
  end

  def load_system_settings
    case @type
		when Boat
      pcharacter_name = Data.system.boat_name
			@character_index = Data.system.boat_index
			@bgm = Data.system.boat_music
			@map_id = Data.treemap.start.boat_map_id
			@x = Data.treemap.start.boat_x
			@y = Data.treemap.start.boat_y
		when Ship
      @character_name = Data.system.ship_name
			@character_index = Data.system.ship_index
			@bgm = Data.system.ship_music
			@map_id = Data.treemap.start.ship_map_id
			@x = Data.treemap.start.ship_x
			@y = Data.treemap.start.ship_y
		when Airship
      @character_name = Data.system.airship_name
			@character_index = Data.system.airship_index
			@bgm = Data.system.airship_music
			@map_id = Data.treemap.start.airship_map_id
			@x = Data.treemap.start.airship_x
			@y = Data.treemap.start.airship_y
    end
  end

  def refresh
    if @driving
      map_id = Game_Map.map_id
      sync_with_player
    elsif map_id == Game_Map.map_id
      move_to(x, y)
    end

    case @type
		when Boat
			@priority_type = RPG::EventPage::Layers_same
			@move_speed = RPG::EventPage::MoveSpeed_normal
		when Ship
			@priority_type = RPG::EventPage::Layers_same
			@move_speed = RPG::EventPage::MoveSpeed_double
		when Airship
			@priority_type = @driving ? RPG::EventPage::Layers_above : RPG::EventPage::Layers_below
			@move_speed = RPG::EventPage::MoveSpeed_fourfold
    end
    @walk_animation = driving
  end

  def set_position(map, x, y)
    @map_id = map
    @x, @y = x, y
  end

  def in_position?(x, y)
    @map_id == Game_Map.map_id and Game_Character.in_position?(x, y)
  end

  def visible; @map_id != Game_Map.map_id or !Game_Character.visible; end

  def get_on
    @driving = true
    @walk_animation = true
    @priority_type = RPG::EventPage::Layers_above if @type == Airship
    Game_System.bgm_play bgm
  end

  def get_off
    @driving = false
    @walk_animation = false
    @direction = RPG::EventPage::Direction_left
  end

  def speed; @move_speed; end
  def screen_y; Game_Character.screen_y - @altitude; end
  def movable?
    return false if @type == Airship and @altitude < MAX_ALTITUDE
    moving?
  end

	def sync_with_player
    @x, @y = $game_player.x, $game_player.y
    @real_x, @real_y = $game_player.real_x, $game_player.real_y
    @direction = $game_player.direction
    update_bush_depth
  end

  def update
    super
    if @type == Airship
      if @driving
        @altitude += 1 if @altitude < MAX_ALTITUDE
      elsif @altitude > 0
        @altitude -= 1
        @priority_type = RPG::EventPage::Layers_below if @altitude == 0
      end
    end
  end

	def check_event_trigger_touch(x, y); false; end
end
