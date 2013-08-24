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

# Base class used by the save and load scenes.
class Scene_File < Scene

	# Constructor.
	#
	# @param message title message.
	def initialize(t, message)
    super t
    @index = 0
    @top_index = 0
    @help_window = nil
    @message = message
    @file_windows = []
  end

	def start
    # Create the windows
    @help_window = Window_Help.new 0, 0, 320, 32
    @help_window.text = message

	for i in 0...15
    w = Window_SaveFile.new 0, 40 + i * 64, 320, 64
		w.index = i

		# Try to access file
		file = FileFinder.find_default('Save%02d.lsd' % (i + 1))
		if not file.nil?
			# File found
			savegame = LSD_Reader.load file

			if not savegame.nil?
				# When a face_name is empty the party list ends
        party_size =
					savegame.title.face1_name.empty? ? 0 :
					savegame.title.face2_name.empty? ? 1 :
					savegame.title.face3_name.empty? ? 2 :
					savegame.title.face4_name.empty? ? 3 : 4

				party = Array.new party_size

        party[3] = [savegame.title.face4_id, savegame.title.face4_name] if party_size == 4
        party[2] = [savegame.title.face3_id, savegame.title.face3_name] if party_size == 3
        party[1] = [savegame.title.face2_id, savegame.title.face2_name] if party_size == 2
        party[0] = [savegame.title.face1_id, savegame.title.face1_name] if party_size == 1

				w.set_party(party,
                    savegame.title.hero_name,
                    savegame.title.hero_hp,
                    savegame.title.hero_level)
			else
				w.corrupted = true
			end
		end

		w.refresh
		@file_windows.push w
	end

	refresh
  end

	def update
    @file_windows.each_with_index { |v,i|
      v.update
    }

    if Input.triggered? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      Scene.pop
    elsif Input.triggered? Input::DECISION
      Game_System.se_play $game_data.system.decision_se
      action @index
      Scene.pop
    end

    old_top_index = @top_index
    old_index = @index

    if Input.repeated? Input::DOWN
      Game_System.se_play $game_data.system.cursor_se
      @index += 1
      @index -= 1 if @index >= @file_windows.length

      @top_index = [@top_index, @index - 3 + 1].max
    end
    if Input.repeated? Input::UP
      Game_System.se_play $game_data.system.cursor_se
      @index -= 1
      @index += 1 if @index < 0
      @top_index = [@top_index, @index].min
    end

    refresh if (@top_index != old_top_index || @index != old_index)
  end

	def refresh
    @file_windows.each_with_index { |w,i|
      w.y(40 + (i - @top_index) * 64)
      w.active = i == @index
      w.visible = i >= @top_index && i < @top_index + 3
    }
  end
end
