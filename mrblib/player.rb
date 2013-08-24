module Player
  EngineRpg2k = 0
  EngineRpg2k3 = 1
end

class << Player
  @exit_flag = false
  @reset_flag = false
  @debug_flag = false
  @hide_title_flag = false
  @window_flag = false
  @battle_test_flag = false
  @battle_test_troop_id = 0
  @engine = Player::EngineRpg2k

  def rpg2k?; @engine == Player::EngineRpg2k; end
  def rpg2k3?; @engine == Player::EngineRpg2k3; end

  def arg_exists(args, name)
    idx = args.index(name)
    args.delete_at idx unless idx.nil?
    not idx.nil?
  end

  def parse_args(args)
    if args.length > 1 and args[1].downcase == 'battletest'
      @battle_test_flag = true
      @battle_test_troop_id = args.length > 4 ? args[4].to_i : 0
    else
      lowered_args = args.map { |v| v.downcase }
      lowered_args.shift # remove executable name

      @window_flag = arg_exists args, 'window'
      @debug_flag = arg_exists args, 'testplay'
      @hide_title_flag = arg_exists args, 'hidetitle'

      Output.debug 'Unknown arguments: %s' % lowered_args unless lowered_args.empty?
    end

    if $DEBUG
      @debug_flag = true
      @window_flag = true
    end
  end

  def run
    Scene.push Scene.create_null_scene
    if FileFinder.rpg2k_project? FileFinder.project_tree
      Scene.push debug_flag ? Scene_Title.new : Scene_Logo.new
    else
      Scene.push Scene_ProjectFinder.new
    end

    @reset_flag = false

    # Reset frames before starting
    Graphics.frame_reset

    until Scene.instance.nil?
      Scene.instance.main_function
      for i in 0...Scene.old_instances.length; Graphics.pop; end
      @old_instances.clear
    end
  end

  def pause
    Audio.bgm_pause
  end

  def resume
    Input.reset_keys
    Audio.bgm_resume
    Graphics.frame_reset
  end

  def update
    Graphics.fps_on_screen = !Graphics.fps_on_screen if Input.triggered? Input::TOGGLE_FPS

    # use debug output for log viewer
    # Output.take_screenshot
    Output.debug "Screenshot request from user." if Input.triggered? Input::TAKE_SCREENSHOT

    if Input.triggered? Input::LOG_VIEWER
      Scene.find("Log Viewer").nil? ? Scene.pop : Scene.push(Scene_LogViewer.new)
    end

    Output.update

    if exit_flag
      Scene.pop_until nil
    elsif reset_flag
      @reset_flag = false
      Scene.pop_until 'Title'
    end
  end

  attr_reader(:debug_flag, :hide_title_flag, :window_flag,
              :battle_test_flag, :battle_test_troop_id)

  attr_accessor :reset_flag, :exit_flag, :engine
end
