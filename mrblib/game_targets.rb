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

module Game_Targets
  data = Main_Data.game_data.targets

	def add_teleport_target(map_id, x, y, switch_id)
    target = find_target map_id, true
    target.map_id = map_id
    target.map_x = x
    target.map_y = y
    target.switch_on = !switch_id.nil?
    target.switch_id = switch_id unless switch_id.nil?
  end

	def remove_teleport_target(map_id); data.delete map_id; end

	def set_escape_target(map_id = nil, x = nil, y = nil, switch_id = nil)
    target = find_target 0, true
    target.map_id = map_id
    target.map_x = x
    target.map_y = y
    target.switch_on = !switch_id.nil?
    target.switch_id = switch_id unless switch_id.nil?
  end

	def teleport_target(map_id); find_target map_id, false; end
  def escape_target; find_target 0, false; end

  def find_target(id, create)
    data[id] = {} if create and not data.key? id
    data.key? id ? data[id] : nil
  end
end
