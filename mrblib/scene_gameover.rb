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

# Scene Game Over class.
# Displays the Game Over screen.
class Scene_Gameover < Scene

	# Constructor.
  def initialize; super "Gameover"; end

	def start
    # Load Background Graphic
    @background = Sprite.new
    @background.bitmap = Cache.gameover Data.system.gameover_name

    # Stop current music
    Audio.bgm_stop
    Audio.bgs_stop

    # Play gameover music
    Game_System.bgm_play Game_System.system_bgm(Game_System::BGM_GameOver)
  end

	def update
    if Input.trigger? Input::DECISION
      Scene.pop_until 'Title'
    end
  end
end
