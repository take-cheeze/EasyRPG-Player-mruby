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

# Scene Title class.
class Scene_Title < Scene
	# Constructor.
	def initialize
    super 'Title'

    @command_window = nil
    @title = nil
    @continue_enabled = false
    @init = false
  end

	def start
    load_database

    version = Data.system.version
    Output.debug('switching to RPG%d interpreter' % version)
    Player.engine = version == 2003 ? Player::EngineRpg2k3 : Player::EngineRpg2k

    if not @init
      FileFinder.update_rtp_paths
      @init = true
    end

    $game_data = {}

    # Create Game System
    Game_System.init

    if !Player.battle_test_flag
      create_title_graphic
      play_title_music
    end

    create_command_window
  end

	def continue
    # Clear the cache when the game returns to title screen
    # e.g. by pressing F12
    Cache.clear

    start
  end

	def transition_in
    if !Player.battle_test_flag
      Graphics.transition_2k Graphics::TransitionErase, 1, true
      Graphics.transition_2k Graphics::TransitionFadeIn, 32
    end
  end

	def transition_out
    if !Player.battle_test_flag
      Graphics.transition_2k Graphics::TransitionFadeOut, 12, true
    end
  end

	def suspend
    @command_window.visible = false
  end

	def resume
    @command_window.visible = true
  end

	def update
    if Player.battle_test_flag
      prepare_battle_test
      return
    end

    @command_window.update

    if Input.trigger? Input::DECISION
      case @command_window.index
      when 0; command_new_game # New Game
      when 1; command_continue # Load Game
      when 2; command_shutdown # Exit Game
      end
    end
  end

  DATABASE_NAME = "RPG_RT.ldb"
  TREEMAP_NAME = "RPG_RT.lmt"

	# Loads all databases.
	def load_database
	# Load Database
    Data.clear

    if ! FileFinder.rpg2k_project? FileFinder.project_tree
      Output.debug('%s is not an RPG2k project' % $project_path)
    end

    Data.load_ldb FileFinder.find_default(DATABASE_NAME)
    Data.load_lmt FileFinder.find_default(TREEMAP_NAME)
  end

	# Initializes all game classes.
	def create_game_objects
    Game_Temp.init
    $game_screen = Game_Screen.new
    Game_Actors.init
    Game_Party.init
    Game_Message.init
    Game_Map.init
    $game_player = Game_Player.new
  end

	# Checks if there are any savegames for the game.
	#
	# @return true if there are any, false otherwise.
  def check_continue
    for i in 1..15
      return true if not FileFinder.find_default('Save%02d.lsd' % i).nil?
    end
    false
  end

	# Creates the background graphic of the scene.
	def create_title_graphic
    # Load Title Graphic
    if !@title # No need to recreate Title on Resume
      @title = Sprite.new
      @title.bitmap = Cache.title Data.system.title
    end
  end

	# Creates the Window displaying the options.
	def create_command_window
    # Create Options Window
    options = [Data.terms.new_game, Data.terms.load_game, Data.terms.exit_game]
    @command_window = Window_Command.new options
    @command_window.x = 160 - @command_window.width / 2
    @command_window.y = 224 - @command_window.height

    # Enable load game if available
    @continue_enabled = check_continue
    if @continue_enabled; @command_window.index = 1
    else; @command_window.disable_item 1
    end

    # Set the number of frames for the opening animation to last
    @command_window.open_animation = 32
    @command_window.visible = false
  end

	# Plays the title music.
	def play_title_music; Game_System.bgm_play Data.system.title_music; end

	# Checks if there is a player start location.
	#
	# @return true if there is one, false otherwise.
	def check_valid_player_location; Data.treemap.start.party_map_id != 0; end

	# Initializes a battle test session.
	def prepare_battle_test
    create_game_objects
    # Game_Party.setup_battle_test_members
    # Game_Troop.can_escape = true
    Game_System.bgm_play Data.system.battle_music

    Scene.push Scene_Battle, true
  end

	# Option New Game.
	# Starts a new game.
	def command_new_game
    if !check_valid_player_location
      Output.warning "The game has no start location set."
    else
      Game_System.se_play $game_data.system.decision_se
      Audio.bgm_stop
      Graphics.frame_count = 0
      create_game_objects
      Game_Map.setup Data.treemap.start.party_map_id
      $game_player.move_to Data.treemap.start.party_x, Data.treemap.start.party_y
      $game_player.Refresh()
      Game_Map.autoplay
      Scene.push Scene_Map.new
    end
  end

	# Option Continue.
	# Shows the Load-Screen (Scene_Load).
	def command_continue
    if @continue_enabled
      Game_System.se_play $game_data.system.decision_se
    else
      Game_System.se_play $game_data.system.buzzer_se
      return
    end

    # Change scene
    Scene.push Scene_Load.new
  end

	# Option Shutdown.
	# Does a player shutdown.
	def command_shutdown
    Game_System.se_play $game_data.system.decision_se
    Audio.bgs_fade(800)
    Scene.pop
  end
end
