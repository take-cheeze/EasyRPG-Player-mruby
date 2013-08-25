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

# Game Player class
class Game_Player < Game_Character
  def initialize
    @teleporting = false
    @vehicle_type = nil
    @vehicle_getting_on = false
    @vehicle_getting_off = false
    @new_map_id = 0
    @new_x, @new_y = 0, 0
  end

  def passable?(x, y, d)
    new_x = x + (d == RPG::EventPage::Direction_right ? 1 :
                 d == RPG::EventPage::Direction_left ? -1 : 0)
    new_y = y + (d == RPG::EventPage::Direction_down ? 1 :
                 d == RPG::EventPage::Direction_up ? -1 : 0)

    return false if not Game_Map.valid? new_x, new_y
    return true if Player.debug_flag and Input.pressed? Input::DEBUG_THROUGH

    Game_Character.passable? x, y, d
  end

  def teleporting?; @teleporting; end

  def reserve_teleport(map_id, x, y)
    @new_map_id = map_id
    @new_x, @new_y = x, y
  end

  def start_teleporting; @teleporting = true end

  def perform_teleporting
    return if not @teleporting

    @teleporting = false

    if Game_Map.map_id != @new_map_id
      @move_route_owner = nil
      refresh
      Game_Map.setup(@new_map_id)
    end

    $game_player.opacity = 255

    move_to @new_x, @new_y
  end

	def center(x, y)
    @center_x = (Graphics.screen_buffer.width / 2 - 16) * 8
    @center_y = (Graphics.screen_buffer.height / 2 - 8) * 8

    max_x = (Game_Map.width - Graphics.screen_buffer.width / 16) * 128
    max_y = (Game_Map.height - Graphics.screen_buffer.height / 16) * 128
    Game_Map.display_x = [0, [x * 128 - center_x, max_x].min].max
    Game_Map.display_y = [0, [y * 128 - center_y, max_y].min].max
  end

  def move_to(x, y)
    Game_Character.move_to x, y
    center x, y
  end

  def update
    last_moving = moving?

    if moving? && !Game_Map.interpreter.running?
      # move_route_forcing || Game_Temp::message_window_showing
      case Input.dir4
			when 2; move_down
			when 4; move_left
			when 6; move_right
			when 8; move_up
      end
    end

    last_real_x = @real_x
    last_real_y = @real_y

    super
    update_scroll last_real_x, last_real_y
    update_non_moving last_moving
  end

	def refresh
    if Game_Party.actors.empty?
      @character_name = ''
      return
    end

    actor = Game_Party.actors[0]
    @character_name, @character_index = actor.character_name, actor.character_index
  end

	def check_event_trigger_touch(x, y)
    return false if Game_Map.interpreter.running?

    result = false
    for i in Game_Map.events_xy(x, y)
      if i.priority_type == 1 and (i.trigger == 1 or i.triggers == 2)
        i.start
        result = true
      end
    end
    result
  end

  def check_event_trigger_there(triggers)
    return false if Game_Map.interpreter.running?

    result = false

    front_x = Game_Map.x_with_direction @x, @direction
    front_y = Game_Map.y_with_direction @y, @direction

    for i in Game_Map.events_xy(front_x, front_y)
      if i.priority_type ~~ RPG::EventPage::Layers_same and !triggers.find(i.trigger).nil?
        i.start
        result = true
      end
    end

    if !result and Game_Map.is_counter?(front_x, front_y)
      front_x = Game_Map.x_with_direction @x, @direction
      front_y = Game_Map.y_with_direction @y, @direction

      for i in Game_Map.events_xy(front_x, front_y)
        if i.priority_type == 1 and !triggers.find(i.trigger).nil?
          i.start
          result = true
        end
      end
    end

    result
  end

  def movable?
    return false if moving?
    return false if move_route_forcing?
    return false if @vehicle_getting_on
    return false if @vehicle_getting_off
    return false if Game_Message.visible
    return false if in_airship? and !Game_Map.vehicle(Game_Vehicle::Airship).movable?
    true
  end
  def in_vehicle?; not @vehicle_type.nil? end
  def in_airship?; @vehicle_type == Game_Vehicle::Airship end

  def airship_land_ok(x, y)
    # Game_Map.airship_land_ok(x, y)
    Game_Map.events_xy(x, y).empty?
  end

  def can_walk?(x, y)
    last_vehicle_type = @vehicle_type
    @vehicle_type = nil
    result = passable? x, y, @direction
    @vehicle_type = last_vehicle_type
    result
  end

  def update_scroll(last_real_x, last_real_y)
    center_x = (Graphics.screen_buffer.width / 2 - 16) * 8
    center_y = (Graphics.screen_buffer.height / 2 - 8) * 8

    return if Game_Map.pan_locked?

    if Game_Map.pan_x != 0 || Game_Map.pan_y != 0
      int dx = real_x - center_x + Game_Map.pan_x - Game_Map.display_x
      int dy = real_y - center_y + Game_Map.pan_y - Game_Map.display_y

      Game_Map.scroll_right(dx) if (dx > 0)
      Game_Map.scroll_left(-dx) if (dx < 0)
      Game_Map.scroll_down(dy) if (dy > 0)
      Game_Map.scroll_up(-dy) if (dy < 0)
    else
      Game_Map.scroll_down(real_y - last_real_y) if (real_y > last_real_y && real_y - Game_Map.display_y > center_y)
      Game_Map.scroll_left(last_real_x - real_x) if (real_x < last_real_x && real_x - Game_Map.display_x < center_x)
      Game_Map.scroll_right(real_x - last_real_x) if (real_x > last_real_x && real_x - Game_Map.display_x > center_x)
      Game_Map.scroll_up(last_real_y - real_y) if (real_y < last_real_y && real_y - Game_Map.display_y < center_y)
    end
  end

  def update_non_moving(last_moving)
    return if Game_Map.interpreter.running?
    return if moving?
    return if last_moving and check_touch_event

    if !Game_Message.visible and Input.trigger? Input::DECISION
      # TODO: return if get_on_off_vehicle
      return if check_action_event
    end

    Game_Map..update_encounter_steps if last_moving
  end

  def check_action_event
    # TODO: return false if is_in_airship?
    check_event_trigger_here([0]) or check_event_trigger_there([0, 1, 2])
  end

  def check_touch_event; check_event_trigger_here [1, 2] end

  def check_event_trigger_here(triggers)
    return false if Game_Map.interpreter.running?

    result = false

    for i in Game_Map.events_xy(@x, @y)
      if i.priority_type == RPG::EventPage::Layers_below and !triggers.find(i.trigger).nil?
        i.start
        result = i.starting?
      end
    end
    result
  end

  def get_on_off_vehicle
    return false if !movable?
    in_vehicle? ? get_off_vehicle : get_on_vehicle
  end

  def get_on_vehicle
    front_x = Game_Map.x_with_direction x, direction
    front_y = Game_Map.y_with_direction y, direction

    if Game_Map.vehicle(Game_Vehicle::Airship).is_in_position?(x, y)
      type = Game_Vehicle::Airship
    elsif Game_Map.vehicle(Game_Vehicle::Ship).is_in_position?(front_x, front_y)
      type = Game_Vehicle::Ship
    elsif Game_Map.vehicle(Game_Vehicle::Boat).is_in_position?(front_x, front_y)
      type = Game_Vehicle::Boat
    else return false end

    @vehicle_getting_on = true
    @vehicle_type = type
    @through = true if type == Game_Vehicle::Airship
    # TODO:
    # else
    # 	ForceMoveForward()
    pwalking_bgm = Game_System.current_bgmm
    Game_Map.vehicle(type).get_on
    true
  end

	def get_off_vehicle
    if in_airship?
      return false if not airship_land_ok(x, y)
    else
      front_x = Game_Map.x_with_direction x, direction
      front_y = Game_Map.y_with_direction y, direction
      return false if !can_walk?(front_x, front_y)
    end

    Game_Map.vehicle(vehicle_type).get_off
    if in_airship?
      @direction = RPG::EventPage::Direction_down
    else
      # TODO
      # ForceMoveForward()
      popacity = 255
    end

    @vehicle_getting_off = true
    @move_speed = 4
    @through = false
    Game_System.bgm_play @walking_bgm

    true
  end
end
