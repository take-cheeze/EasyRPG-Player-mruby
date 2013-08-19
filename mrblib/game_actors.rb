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

# Game_Actors namespace.
module Game_Actors
	# Initializes Game Actors.
	def load
    @data = Array.new(Data.actors.size + 1)
    for i in 1...@data.length
      actor(i).load
    end
  end

	# Disposes Game Actors.
	def clear
    @data = []
  end

	# Gets an actor by its ID.
	#
	# @param id the actor ID in the database.
	# @return the actor object.
	def actor(id)
    if not actor_exists? id
      Output.Warning("Actor ID %d is invalid" % id)
      nil
    elsif data[id].nil?
      @data[id] = Game_Actor.new id
    else
      @data[id]
    end
  end

	# Gets if an actor ID is valid.
	#
	# @param id the actor ID in the database.
	# @return whether the actor exists.
	def actor_exists?(id)
    id > 0 and id < @data.length
  end
end
