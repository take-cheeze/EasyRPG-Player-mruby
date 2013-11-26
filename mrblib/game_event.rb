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
    super()

    @starting = false
    @map_id = id
    @event = event
    @pages = event.page
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
    new_page_key = @erased ? nil : @pages.keys.reverse!.find { |v| are_conditions_met @pages[v] }
    new_page = new_page_key && @pages[new_page_key]

    if new_page != @page
      clear_starting
      setup new_page
      check_event_trigger_auto
    end
  end

  def setup(new_page)
    @page = new_page
    if @page.nil?
      @tile_id = 0
      @character_name = ''
      @character_index = 0
      @direction = RPG::EventPage::Direction_down
      @through = true
      @trigger = nil
      @list = []
      @interpreter = nil
    else
      @character_name = @page[:charset]
      @character_index = @page.charset_pos

      @tile_id = @character_name.nil? ? @character_index : 0

      if @original_direction != @page.charset_dir
        @direction = @page.charset_dir
        @original_direction = direction
        @prelock_direction = nil
      end

      if @original_pattern != @page.charset_pat
        @pattern = @page.charset_pat
        @original_pattern = pattern
      end
      # opacity = @page.opacity
      # opacity = @page.translucent ? 192 : 255
      # blend_type = @page.blend_type
      @move_type = @page.action
      @move_speed = @page.speed
      @move_frequency = @page.frequency
      self.move_route = @page.move
      @move_route_index = 0
      @move_route_forcing = false
      # @animation_type = @page.animation_type
      # @through = page
      # @always_on_top = @page.overlap
      @priority_type = @page.priority_type
      @trigger = @page.trigger
      @list = @page.event
      @through = false

      interpreter = Game_Interpreter_Map.new if @trigger == RPG::EventPage::Trigger_parallel
      check_event_trigger_auto
    end
  end

  FlagSwitch1 = 0x1 << 0
  FlagSwitch2 = 0x1 << 1
  FlagVariable = 0x01 << 2
  FlagItem = 0x01 << 3
  FlagActor = 0x01 << 4
  FlagTimer1 = 0x01 << 5
  FlagTimer2 = 0x01 << 6

  CompareOperator = [:==, :>=, :<=, :>, :<, '!='.to_sym]

  def are_conditions_met(page)
    term = page.term
    flags = term.flags

    # First switch (A)
    return false if (flags & FlagSwitch1) != 0 && !Game_Switches[term.switch_id1]

    # Second switch (B)
    return false if (flags & FlagSwitch2) != 0 && !Game_Switches[term.switch_id2]

    # Variable
    if Player.rpg2k? and (flags & FlagVariable) != 0 && !(Game_Variables[term.variable_id] >= term.variable_value)
      return false
    else
      if (flags & FlagVariable) != 0
        return false unless Game_Variables[term.variable_id].
          send(CompareOperator[term.compare_operator], term.variable_value)
      end
    end

    # Item in possession?
    return false if (flags & FlagItem) != 0 && !Game_Party.item_number(term.item_id)

    # Actor in party?
    return false if (flags & FlagActor) != 0 and not Game_Party.actor_in_party?(term.actor_id)

    # Timer
    return false if (flags & FlagTimer1) != 0 and
      Game_Party.read_timer(Game_Party::Timer1) > term.timer_sec * DEFAULT_FPS

    # Timer2
    return false if (flags & FlagTimer2) != 0 and
      Game_Party.read_timer(Game_Party::Timer2) > term.timer_sec * DEFAULT_FPS

    # All conditions met :D
    true
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
      $game_player.in_position?(x, y) and
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
