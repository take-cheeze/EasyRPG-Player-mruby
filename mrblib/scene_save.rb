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

# Scene_Item class.
class Scene_Save < Scene_File
	# Constructor.
  def initialize; super "Save", Data.terms.save_game_message; end

	def action(index)
    # TODO: Maybe find a better place to setup the save file?
    title = {}

    size = Game_Party.actors.length

    if size >= 4
      actor = Game_Party.actors[3]
			title.face4_id = actor.face_index
			title.face4_name = actor.face_name
    end
   if size >= 3
      actor = Game_Party.actors[2]
			title.face3_id = actor.face_index
			title.face3_name = actor.face_name
    end
   if size >= 2
      actor = Game_Party.actors[1]
			title.face2_id = actor.face_index
			title.face2_name = actor.face_name
    end
   if size >= 1
      actor = Game_Party.actors[0]
			title.face1_id = actor.face_index
			title.face1_name = actor.face_name

			title.hero_hp = actor.hp
			title.hero_level = actor.level
			title.hero_name = actor.name
    end

    Main_Data.game_data.title = title

    Main_Data.game_data.system.save_slot = index + 1
    Main_Data.game_data.system.save_count += 1

    LSD_Reader.save FileFinder.find_default('Save%02d.sd' % (index + 1)), Main_Data.game_data
  end
end
