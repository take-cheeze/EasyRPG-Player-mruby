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

module Game_Actors end

class << Game_Actors
  # Initializes Game Actors.
  def load
    $game_data.actor ||= []
    @objects = []
  end

  def data; $game_data.actor; end

  # Disposes Game Actors.
  def clear
    data.clear
    @objects.clear
  end

  # Gets an actor by its ID.
  #
  # @param id the actor ID in the database.
  # @return the actor object.
  def actor(id)
    if not actor_exists? id
      Output.warning("Actor ID %d is invalid" % id)
      nil
    else
      @objects[id] ||= Game_Actor.new id
    end
  end

  # Gets if an actor ID is valid.
  #
  # @param id the actor ID in the database.
  # @return whether the actor exists.
  def actor_exists?(id)
    not Data.actor[id].nil?
  end
end
