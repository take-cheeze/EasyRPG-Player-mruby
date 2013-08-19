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

# Game_CommonEvent class.
class Game_CommonEvent
	# Constructor.
	#
	# @param common_event_id database common event ID.
	# @param battle FIXME.
	def initialize(id, battle = false)
    @common_event_id = id
    @battle = battle
    @interpreter = nil
  end

	# Refreshes the common event.
	def refresh
    if (trigger == RPG::EventPage::Trigger_parallel)
      if (switch_flag() ? Game_Switches[switch_id] : true)
        if (@interpreter.nil?)
          @interpreter = battle ? Game_Interpreter_Battle.new : Game_Interpreter_Map.new
          update
        end
      else
        @interpreter = nil
      end
    else
      @interpreter = nil
    end
  end

	# Updates common event interpreter.
	def update
    return if @interpreter.nil?
    @interpreter.setup list, 0 if not Game_Map.interpreter.running?
    @interpreter.update
  end

	# Gets common event index.
	#
	# @return common event index in list.
  def index; @common_event_id; end

	# Gets common event name.
	#
	# @return event name.
  def name; Data.commonevents[@common_event_id].name; end

	# Gets trigger condition.
	#
	# @return trigger condition.
  def trigger; Data.commonevents[@common_event_id].trigger; end

	# Gets if an event has a switch.
	#
	# @return flag if that event has a switch.
	def switch_flag; Data.commonevents[@common_event_id].switch_flag; end

	# Gets trigger switch ID.
	#
	# @return trigger switch ID.
  def switch_id; Data.commonevents[@common_event_id].switch_id; end

	# Gets event commands list.
	#
  # @return event commands list.
  def list; Data.commonevents[@common_event_id].event_commands; end
end
