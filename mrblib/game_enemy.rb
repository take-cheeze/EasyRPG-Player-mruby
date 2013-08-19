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

class Game_Enemy < public Game_Battler
  def initialize(id)
    @enemy_id = id
    @hp = max_hp
    @sp = max_sp
    @hidden = false
  end

  def hidden?; @hidden; end
  def hide; @hidden = true; end

  attr_reader :states, :hp, :sp

  def hp=(v); @hp = [0, [v, max_hp].min].max; end
  def sp=(v); @sp = [0, [v, max_sp].min].max; end

  def transform(id); @enemy_id = id; end

	# Gets the maximum HP for the current level.
	#
	# @return maximum HP.
  def base_max_hp; Data.enemies[@enemy_id].max_hp; end

	# Gets the maximum SP for the current level.
	#
	# @return maximum SP.
  def base_max_sp; Data.enemies[@enemy_id].max_sp; end

	# Gets the attack for the current level.
	#
	# @return attack.
  def base_attack; Data.enemies[@enemy_id].attack; end

	# Gets the defense for the current level.
	#
	# @return defense.
  def base_defence; Data.enemies[@enemy_id].defence; end

	# Gets the spirit for the current level.
	#
	# @return spirit.
  def base_spirit; Data.enemies[@enemy_id].spirit; end

	# Gets the agility for the current level.
	#
	# @return agility.
  def base_agility; Data.enemies[@enemy_id].agility; end
end
