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

# Game_Event class.
class Game_Event < Game_Character
  attr_reader :event, :trigger, :id, :list

	# Gets if the event has been disabled.
	#
	# @return if the event has been disabled (via EraseEvent-EventCommand).
  def disabled?; @erased; end

	# Sets disabled flag for the event (enables or disables it).
	#
	# @param dis_flag enables or disables the event.
  def disabled=(v); @erased = v; end

  def starting?; @starting; end

	# Constructor.
	def initialize(map_id, event)
    @starting = false
    @map_id = id
    @event = event
    @erased = false
    @page = nil
    @id = event.index
    @through = true

    move_to event.x, event.y
    refresh
  end

	# Clears starting flag.
  def clear_starting; @starting = false; end

	# Does refresh.
	def refresh
    new_page = @erased ? nil : @event.reverse.find { |v| are_conditions_met v }

    if new_page != @page
      clear_starting
      setup new_page
      check_event_trigger_auto
    end
  end

	def setup(new_page)
    @page = new_page
    if page.nil?
      @tile_id = 0
      @character_name = ''
      @character_index = 0
      @direction = RPG::EventPage::Direction_down
      @through = true
      @trigger = nil
      @list = []
      @interpreter = nil
    else
      @character_name = page.character_name
      @character_index = page.character_index

      @tile_id = page.character_name.empty? ? page.character_index : 0

      if @original_direction != page.character_direction
        @direction = page.character_direction
        @original_direction = direction
        @prelock_direction = nil
      end

      if @original_pattern != page.character_pattern
        @pattern = page.character_pattern
        @original_pattern = pattern
      end
      # opacity = page.opacity
      # opacity = page.translucent ? 192 : 255
      # blend_type = page.blend_type
      @move_type = page.move_type
      @move_speed = page.move_speed
      @move_frequency = page.move_frequency
      @move_route = page.move_route
      @move_route_index = 0
      @move_route_forcing = false
      # @animation_type = page.animation_type
      # @through = page
      # @always_on_top = page.overlap
      @priority_type = page.priority_type
      @trigger = page.trigger
      @list = page.event_commands
      @through = false

      # Free resources if needed
      interpreter = nil
      if @trigger == RPG::EventPage::Trigger_parallel
        interpreter= Game_Interpreter_Map.new
      end
      check_event_trigger_auto
    end
  end

	def are_conditions_met(page)
    # First switch (A)
    return false if page.condition.flags.switch_a && !Game_Switches[@page.condition.switch_a_id]

    # Second switch (B)
    return false if page.condition.flags.switch_b && !Game_Switches[page.condition.switch_b_id]

    # Variable
    if Player.rpg2k? and page.condition.flags.variable && !(Game_Variables[page.condition.variable_id] >= page.condition.variable_value)
      return false
    else
      if (page.condition.flags.variable)
        case page.condition.compare_operator
        when 0 # ==
          return false if (!(Game_Variables[page.condition.variable_id] == page.condition.variable_value))
        when 1 # >=
          return false if (!(Game_Variables[page.condition.variable_id] >= page.condition.variable_value))
        when 2 # <=
          return false if (!(Game_Variables[page.condition.variable_id] <= page.condition.variable_value))
        when 3 # >
          return false if (!(Game_Variables[page.condition.variable_id] > page.condition.variable_value))
        when 4 # <
          return false if (!(Game_Variables[page.condition.variable_id] < page.condition.variable_value))
        when 5 # !=
          return false if (!(Game_Variables[page.condition.variable_id] != page.condition.variable_value))
        end
      end
    end

    # Item in possession?
    return false if page.condition.flags.item && !Game_Party::ItemNumber(page.condition.item_id)

    # Actor in party?
    return false if page.condition.flags.actor and
      !Game_Party::IsActorInParty(page.condition.actor_id)

    # Timer
		return false if page.condition.flags.timer and
      Game_Party.read_timer(Game_Party::Timer1) > page.condition.timer_sec * DEFAULT_FPS

    # Timer2
		return false if page.condition.flags.timer2 and
      Game_Party.read_timer(Game_Party::Timer2) > page.condition.timer2_sec * DEFAULT_FPS

    # All conditions met :D
    return true
  end

  def update
    super
    check_event_trigger_auto
    if @interpreter
      @interpreter.setup @list, @id, @event.x, @event.y if not @interpreter.running?
      @interpreter.update
    end
  end

  def check_event_trigger_touch(x, y)
    return false if Game_Map.interpreter.running?

    start if @trigger == RPG::EventPage::Trigger_collision and
      Main_Data.game_player.in_position?(x, y) and
      not jumping?
  end

  def check_event_trigger_auto
    start if @trigger == RPG::EventPage::Trigger_auto_start
  end

  def start
    # RGSS scripts consider list empty if size <= 1. Why?
    return if (@list.empty? || @erased)

    @starting = true
    lock if (@trigger < 3)

    if not Game_Map.interpreter.running?
      Game_Map.interpreter.setup_starting_event self
    end
  end
end
