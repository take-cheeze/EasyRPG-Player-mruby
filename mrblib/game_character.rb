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

# Game_Character class.
class Game_Character
  # Constructor.
  def initialize
    @x, @y = 0, 0
    @tile_id = 0
    @character_index = 0
    @real_x, @real_y = 0, 0
    @direction = RPG::EventPage::Direction_down
    @pattern = RPG::EventPage::Frame_middle
    @original_direction = RPG::EventPage::Direction_down
    @original_pattern = RPG::EventPage::Frame_middle
    @last_pattern = 0
    @move_route_forcing = false
    @through = false
    @animation_id = 0
    @move_route = nil
    @original_move_route = nil
    @move_route_index = 0
    @original_move_route_index = 0
    @move_type = RPG::EventPage::MoveType_stationary
    @move_speed = RPG::EventPage::MoveSpeed_normal
    @move_frequency = 6
    @prelock_direction = nil
    @move_failed = false
    @locked = false
    @wait_count = 0
    @anime_count = 0
    @stop_count = 0
    @jump_count = 0
    @walk_animation = true
    @turn_enabled = true
    @direction_fix = false
    @cycle_stat = false
    @priority_type = RPG::EventPage::Layers_same
    @opacity = 255
    @visible = true
    @flash_pending = false
  end

  attr_accessor :visible, :animation_id
  attr_reader(:priority_type, :flash_pending, :opacity, :through, :move_route_forcing,
              :pattern, :direction, :real_x, :real_y, :character_name, :character_index,
              :x, :y, :tile_id)

  def flash_pending?; @flash_pending; end

  # Gets if character is moving.
  #
  # @return whether the character is moving.
  def moving?; @real_x != @x * 128 or @real_y != @y * 128; end

  # Checks if the character is jumping.
  #
  # @return whether the character is jumping.
  def jumping?; @jump_count > 0; end

  # Checks if the character is stopping.
  #
  # @return whether the character is stopping.
  def stopping?; not (moving? or jumping?); end

  # Gets if character the character can walk in a tile
  # with a specific direction.
  #
  # @param x tile x.
  # @param y tile y.
  # @param d character direction.
  # @return whether the character can walk through.
  def passable?(x, y, d)
    new_x = x + (d == RPG::EventPage::Direction_right ? 1 : d == RPG::EventPage::Direction_left ? -1 : 0)
    new_y = y + (d == RPG::EventPage::Direction_down ? 1 : d == RPG::EventPage::Direction_up ? -1 : 0)

    return false if !Game_Map.valid? new_x, new_y
    return true if @through

    return false unless Game_Map.passable? x, y, d, self
    return false unless Game_Map.passable? new_x, new_y, (d + 2) % 4, self

    return false if $game_player.x == new_x and
      $game_player.x == new_y and
      !$game_player.through and
      !character_name.empty?

    true
  end

  # Moves the character to a new tile.
  #
  # @param x tile x.
  # @param y tile y.
  def move_to(x, y)
    @x = x % Game_Map.width
    @y = y % Game_Map.height
    @real_x = x * 128
    @real_y = y * 128
    prelock_direction = -1
  end

  # Updates character state and actions.
  def update
    # if jumping?; update_jump; end
    moving? ? update_move : update_stop

    if @anime_count > 18 - @move_speed * 2
      if @stop_count > 0
        @pattern = @original_pattern
        @last_pattern = @last_pattern == RPG::EventPage::Frame_left ? RPG::EventPage::Frame_right : RPG::EventPage::Frame_left
      else
        if @last_pattern == RPG::EventPage::Frame_left
          if @pattern == RPG::EventPage::Frame_right
            @pattern = RPG::EventPage::Frame_middle
            @last_pattern = RPG::EventPage::Frame_right
          else @pattern = RPG::EventPage::Frame_right
          end
        else
          if @pattern == RPG::EventPage::Frame_left
            @pattern = RPG::EventPage::Frame_middle
            @last_pattern = RPG::EventPage::Frame_left
          else @pattern = RPG::EventPage::Frame_left
          end
        end
      end

      @anime_count = 0
    end

    # if (@wait_count > 0)
    #   @wait_count -= 1
    #   return
    # end

    if @move_route_forcing
      move_type_custom
    elsif not @locked
      update_self_movement
    end
  end

  # Moves on a random route.
  def move_type_random
    return if not stopping?
    case rand % 6
    when 0; @stop_count = 0
    when 1, 2; move_random
    else; move_forward
    end
  end

  # Moves left to right and switches direction if the
  # move failed.
  def move_type_cycle_left_right
    return if not stopping?
    @cycle_stat ? move_left : move_right
    @cycle_stat = @move_failed ? !@cycle_stat : @cycle_stat
  end

  # Moves up and down and switches direction if the
  # move failed.
  def move_type_cycle_up_down
    return if not stopping?
    @cycle_stat ? move_up : move_down
    @cycle_stat = @move_failed ? !@cycle_stat : @cycle_stat
  end

  # Walks to the player.
  def move_type_towards_player
    return if not stopping?
    sx, sy = @x - $game_player.x, @y - $game_player.y
    if sx.abs + sy.abs >= 20; move_random
    else
      case rand % 6
      when 0; move_random
      when 1; move_forward
      else; move_towards_player
      end
    end
  end

  # Walks to the player.
  def move_type_away_from_player
    return if not stopping?
    sx, sy = @x - $game_player.x, @y - $game_player.y
    if sx.abs + abs.y >= 20; move_random
    else
      case rand % 6
      when 0; move_random
      when 1; move_forward
      else move_away_from_player
      end
    end
  end

  def next_move_command
    ret = @move_route_data[@move_route_index]
    @move_route_index += 1
    ret
  end

  def move_command_string
    size = next_move_command
    Array.new(size).map! { |v| next_move_command.chr }.join('')
  end

  def move_route=(v)
    @move_route = v
    @move_route_data = v.data
  end

  # Walks around on a custom move route.
  def move_type_custom
    return if not stopping?
    @move_failed = false

    if @move_route_index >= @move_route_data.length
      # End of Move list
      if @move_route.repeat
        @move_route_index = 0
      elsif @move_route_forcing
        @move_route_forcing = false
        @move_route_owner.end_move_route(move_route) unless @move_route_owner.nil?
        self.move_route = original_move_route
        @move_route_index = original_move_route_index
        @original_move_route = nil
      end
    else
      case next_move_command
      when RPG::MoveCommand::Code::MoveUp; move_up
      when RPG::MoveCommand::Code::MoveRight; move_right
      when RPG::MoveCommand::Code::MoveDown; move_down
      when RPG::MoveCommand::Code::MoveLeft; move_left
      when RPG::MoveCommand::Code::MoveUpright; move_up_right
      when RPG::MoveCommand::Code::MoveDownright; move_down_right
      when RPG::MoveCommand::Code::MoveDownleft; move_down_left
      when RPG::MoveCommand::Code::MoveUpleft; move_up_left
      when RPG::MoveCommand::Code::MoveRandom; move_random
      when RPG::MoveCommand::Code::MoveTowards_hero; move_towards_player
      when RPG::MoveCommand::Code::MoveAway_from_hero; move_away_from_player
      when RPG::MoveCommand::Code::MoveForward; move_forward
      when RPG::MoveCommand::Code::FaceUp; turn_up
      when RPG::MoveCommand::Code::FaceRight; turn_right
      when RPG::MoveCommand::Code::FaceDown; turn_down
      when RPG::MoveCommand::Code::FaceLeft; turn_left
      when RPG::MoveCommand::Code::Turn90DegreeRight; turn_90degrees_right
      when RPG::MoveCommand::Code::Turn90DegreeLeft; turn_90degrees_left
      when RPG::MoveCommand::Code::Turn180Degree; turn_1800degrees
      when RPG::MoveCommand::Code::Turn90DegreeRandom; turn_90degrees_left_or_right
      when RPG::MoveCommand::Code::FaceRandomDirection; face_random_direction
      when RPG::MoveCommand::Code::FaceHero; face_towards_hero
      when RPG::MoveCommand::Code::FaceAwayFromHero; face_away_from_hero
      when RPG::MoveCommand::Code::Wait; wait
      when RPG::MoveCommand::Code::BeginJump; begin_jump
      when RPG::MoveCommand::Code::EndJump; end_jump
      when RPG::MoveCommand::Code::LockFacing; lock
      when RPG::MoveCommand::Code::UnlockFacing; unlock
      when RPG::MoveCommand::Code::IncreaseMovement_speed
        @move_speed = [@move_speed + 1, 6].min
      when RPG::MoveCommand::Code::DecreaseMovement_speed
        @move_speed = [@move_speed - 1, 1].max
      when RPG::MoveCommand::Code::IncreaseMovement_frequence
        @move_frequency = [move_frequency - 1, 1].min
      when RPG::MoveCommand::Code::DecreaseMovement_frequence
        @move_frequency = [move_frequency - 1, 1].max
      when RPG::MoveCommand::Code::SwitchOn # Parameter A: Switch to turn on
        Game_Switches[next_move_command] = true
        Game_Map.needs_refresh = true
      when RPG::MoveCommand::Code::SwitchOff # Parameter A: Switch to turn off
        Game_Switches[next_move_command] = false
        Game_Map.needs_refresh = true
      when RPG::MoveCommand::Code::ChangeGraphic # String: File, Parameter A: index
        @character_name = move_command_string
        @character_index = next_move_command
      when RPG::MoveCommand::Code::PlaySoundEffect # String: File, Parameters: Volume, Tempo, Balance
        file = move_command_string
        vol, pitch, balance = next_move_command, next_move_command, next_move_command
        Audio.se_play file, vol, pitch if (file != "(OFF)")
      when RPG::MoveCommand::Code::WalkEverywhere_on; @through = true
      when RPG::MoveCommand::Code::WalkEverywhere_off; @through = false
      when RPG::MoveCommand::Code::StopAnimation; @walk_animation = false
      when RPG::MoveCommand::Code::StartAnimation; @walk_animation = true
      when RPG::MoveCommand::Code::IncreaseTransp
        self.opacity = [40, opacity - 45].max
      when RPG::MoveCommand::Code::DecreaseTransp
        self.opacity = opacity + 45
      end

      @move_route_index += 1 if @move_route.skippable || !@move_failed
    end
  end

  # Moves the character down.
  def move_down
    turn_down if @turn_enabled
    @move_failed = !passable?(x, y, RPG::EventPage::Direction_down)
    if @move_failed; check_event_trigger_touch(x, y + 1)
    else; turn_down; @y += 1
    end
  end

  # Moves the character left.
  def move_left
    turn_left if @turn_enabled
    @move_failed = !passable?(x, y, RPG::EventPage::Direction_left)
    if @move_failed; check_event_trigger_touch(x - 1, y)
    else; turn_left; @x -= 1
    end
  end

  # Moves the character right.
  def move_right
    turn_right if @turn_enabled
    @move_failed = !passable?(x, y, RPG::EventPage::Direction_right)
    if @move_failed; check_event_trigger_touch(x + 1, y)
    else; turn_right; @x += 1
    end
  end

  # Moves the character up.
  def move_up
    turn_up if @turn_enabled
    @move_failed = !passable?(x, y, RPG::EventPage::Direction_up)
    if @move_failed; check_event_trigger_touch(x, y - 1)
    else; turn_up; @y -= 1
    end
  end

  # Moves the character forward.
  def move_forward
    case @direction
    when RPG::EventPage::Direction_down; move_down
    when RPG::EventPage::Direction_up; move_up
    when RPG::EventPage::Direction_left; move_left
    when RPG::EventPage::Direction_right; move_right
    end
  end

  # Moves the character diagonal (downleft), moves down if blocked.
  def move_down_left # TODO
  end

  # Moves the character diagonal (downright), moves down if blocked.
  def move_down_right # TODO
  end

  # Moves the character diagonal (upleft), moves up if blocked.
  def move_up_left # TODO
  end

  # Moves the character diagonal (downright), moves up if blocked.
  def move_up_right # TODO
  end

  # Does a random movement.
  def move_random
    case rand % 4
    when 0; move_down
    when 1; move_left
    when 2; move_right
    when 3; move_up
    end
  end

  # Does a move to the player hero.
  def move_towards_player
    sx, sy = distance_x_from_player, distance_y_from_player

    if sx != 0 or sy != 0
      if sx.abs > sy.abs
        sx > 0 ? move_left : move_right
        (sy > 0) ? move_up : move_down if @move_failed and sy != 0
      else
        sy > 0 ? move_up : move_down
        sx > 0 ? move_left : move_right if @move_failed and sx != 0
      end
    end
  end

  # Does a move away from the player hero.
  def move_away_from_player
    sx, sy = distance_x_from_player, distance_y_from_player
    if sx != 0 || sy != 0
      if sx.abs > sy.abs
        (sx > 0) ? move_right : move_left
        (sy > 0) ? move_down : move_up if @move_failed && sy != 0
      else
        (sy > 0) ? move_down : move_up
        (sx > 0) ? move_left : move_left if @move_failed && sx != 0
      end
    end
  end

  # Turns the character down.
  def turn_down
    return if @direction_fix
    @direction = RPG::EventPage::Direction_down
    @stop_count = 0
  end

  # Turns the character left.
  def turn_left
    return if @direction_fix
    @direction = RPG::EventPage::Direction_left
    @stop_count = 0
  end

  # Turns the character right.
  def turn_right
    return if @direction_fix
    @direction = RPG::EventPage::Direction_right
    @stop_count = 0
  end

  # Turns the character up.
  def turn_up
    return if @direction_fix
    @direction = RPG::EventPage::Direction_up
    @stop_count = 0
  end

  # Turns the character 90 Degree to the left.
  def turn_90degrees_left
    case @direction
    when RPG::EventPage::Direction_down; turn_left
    when RPG::EventPage::Direction_left; turn_up
    when RPG::EventPage::Direction_right; turn_down
    when RPG::EventPage::Direction_up; turn_right
    end
  end

  # Turns the character 90 Degree to the right.
  def turn_90degrees_right
    case @direction
    when RPG::EventPage::Direction_down; turn_right
    when RPG::EventPage::Direction_left; turn_down
    when RPG::EventPage::Direction_right; turn_up
    when RPG::EventPage::Direction_up; turn_left
    end
  end

  # Turns the character by 180 degree
  def turn_1800degrees
    case @direction
    when RPG::EventPage::Direction_down; turn_up
    when RPG::EventPage::Direction_left; turn_right
    when RPG::EventPage::Direction_right; turn_left
    when RPG::EventPage::Direction_up; turn_down
    end
  end

  # Turns the character 90 Degree to the left or right
  # by using a random number.
  def turn_90degrees_left_or_right
    rand % 2 ? turn_90degrees_left : turn_90degrees_right
  end

  # Character looks in a random direction
  def face_random_direction # TODO
  end

  # Character looks towards the hero.
  def face_towards_hero # TODO
  end

  # Character looks away from the the hero.
  def face_away_from_hero # TODO
  end

  # Character waits.
  def wait # TODO
  end

  # Jump action begins. Does nothing when EndJump-Command is missing.
  def begin_jump # TODO
  end

  # Jump action ends.
  def end_jump # TODO
  end

  # Locks character facing direction.
  def lock
    if not @locked
      @prelock_direction = @direction
      turn_toward_player
      @locked = true
    end
  end

  # Unlocks character facing direction.
  def unlock
    if @locked
      @locked = false
      self.direction = @prelock_direction
    end
  end

  def direction=(v)
    if !@direction_fix && v != -1
      @direction = v
      @stop_count = 0
    end
  end

  # Forces a new, temporary, move route.
  #
  # @param new_route new move route.
  # @param frequency frequency.
  # @param owner the interpreter which set the route.
  def force_move_route(new_route, freq, owner)
    if @original_move_route.nil?
      @original_move_route = move_route
      @original_move_route_index = @move_route_index
      @original_move_frequency = @move_frequency
    end
    self.move_route = new_route
    @move_route_index = 0
    @move_route_forcing = true
    @move_frequency = frequency
    @move_route_owner = owner
    @prelock_direction = nil
    @wait_count = 0
    @move_type_custom
  end

  # Cancels a previous forced move route.
  #
  # @param route previous move route.
  # @param owner the interpreter which set the route.
  def cancel_move_route(route, owner)
    return if (!@move_route_forcing ||
               @move_route_owner != owner ||
               @move_route != route)

    @move_route_forcing = false
    @move_route_owner = nil
    self.move_route = @original_move_route
    @move_route_index = @original_move_route_index
    @original_move_route = nil
  end

  # Tells the character to not report back to the owner.
  # (Usually because the owner got deleted).
  #
  # @param owner the owner of the move route
  #              if the owner is not the real owner
  #              this function does nothing.
  def detach_move_route_owner(owner)
    @move_route_owner = nil if owner == @move_route_owner
  end

  # Gets screen x coordinate in pixels.
  #
  # @return screen x coordinate in pixels.
  def screen_x; (@real_x - Game_Map.display_x + 3) / 8 + 8; end

  # Gets screen y coordinate in pixels.
  #
  # @return screen y coordinate in pixels.
  def screen_y
    (@real_y - Game_Map.display_y + 3) / 8 + 8
  end

  # Gets screen z coordinate in pixels.
  #
  # @return screen z coordinate in pixels.
  def screen_z(height = nil)
    return 999 if @priority_type == RPG::EventPage::Layers_above
    (@real_y - Game_Map.display_y + 3) / 8 + 16
  end

  def turn_toward_player
    sx, sy = distance_x_from_player, distance_y_from_player
    if sx.abs > sy.abs
      (sx > 0) ? turn_left() : turn_right()
    elsif sx.abs < sy.abs
      (sy > 0) ? turn_up() : turn_down()
    end
  end

  def distance_x_from_player
    sx = @x - $game_player.x
    if Game_Map.loop_horizontal
      sx -= Game_Map.width if sx.abs > Game_Map.width / 2
    end
    sx
  end

  def distance_y_from_player
    sy = @y - $game_player.y
    if Game_Map.loop_horizontal
      sy -= Game_Map.width if sy.abs > Game_Map.width / 2
    end
    sy
  end

  def in_position?(x, y); @x == x and @y == y; end

  # Sets opacity of the character.
  #
  # @param opacity New opacity (0 = Invisible, 255 = opaque)
  def opacity=(v); @opacity = [0, [v, 255].min].max; end

  # Used to pass Flash settings to the character sprite.
  # After extracting IsFlashPending returns false.
  #
  # @param color Flash color is written here
  # @param duration Flash duration is written here
  def flash_paramaters
    @flash_pending = false
    return @flash_color, @flash_duration
  end

  # Sets the Flash effect settings.
  # After calling this IsFlashPending returns true.
  #
  # @param color Flash color
  # @param duration Flash duration
  def set_flash(color, duration)
    @flash_pending = true
    @flash_duration = duration
    @flash_color = color

    # 0.0 flash
    duration = DEFAULT_FPS if duration == 0
  end

  def update_bush_depth; end


  def update_move
    distance = (1 << @move_speed)
    @real_y = [@real_y + distance, @y * 128].min if @y * 128 > @real_y
    @real_x = [@real_x - distance, @x * 128].max if @x * 128 < @real_x
    @real_x = [@real_x + distance, @x * 128].min if @x * 128 > @real_x
    @real_y = [@real_y - distance, @y * 128].max if @y * 128 < @real_y
    @anime_count += 1.5 if @walk_animation
  end

  def set_graphic(name, index)
    @character_name = name
    @character_index = index
  end

  CharPlayer    = 10001
  CharBoat    = 10002
  CharShip    = 10003
  CharAirship    = 10004
  CharThisEvent  = 10005

  def self.character(char, event)
    case(char)
    when CharPlayer
      # Player/Hero
      return $game_player
    when CharBoat
      return Game_Map.vehicle(Game_Vehicle::Boat)
    when CharShip
      return Game_Map.vehicle(Game_Vehicle::Ship)
    when CharAirship
      return Game_Map.vehicle(Game_Vehicle::Airship)
    when CharThisEvent
      # This event
      return Game_Map::events.empty? ? nil : Game_Map.events[event]
    else
      # Other events
      return Game_Map.events.empty? ? nil : Game_Map.events[char]
    end
  end

  def update_self_movement
    return if not (@stop_count > 30 * (5 - @move_frequency))
    case @move_type
    when RPG::EventPage::MoveType_random; move_type_random
    when RPG::EventPage::MoveType_vertical; move_type_cycle_up_down
    when RPG::EventPage::MoveType_horizontal; move_type_cycle_left_right
    when RPG::EventPage::MoveType_toward; move_type_towards_player
    when RPG::EventPage::MoveType_away; move_type_away_from_player
    when RPG::EventPage::MoveType_custom; move_type_custom
    end
  end

  def update_stop
    @anime_count += 1.5 if (pattern != @original_pattern)
    @stop_count += 1 # if (!starting || !@locked)
  end
end
