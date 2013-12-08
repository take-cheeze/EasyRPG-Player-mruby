module Player
  EngineRpg2k = 0
  EngineRpg2k3 = 1

  @exit_flag = false
  @reset_flag = false
  @debug_flag = false
  @hide_title_flag = false
  @window_flag = false
  @battle_test_flag = false
  @battle_test_troop_id = 0
  @engine = Player::EngineRpg2k

  @old_instances = []
  @instances = []
  @push_pop_operation = 0 # SceneNop
end

class << Player
  SceneNop = 0
  ScenePushed = 1
  ScenePopped = 2

  def rpg2k?; @engine == Player::EngineRpg2k; end
  def rpg2k3?; @engine == Player::EngineRpg2k3; end

  def arg_exists(args, name)
    idx = args.index(name)
    args.delete_at idx unless idx.nil?
    not idx.nil?
  end

  def push(new_scene)
    @instances.push new_scene
    @push_pop_operation = ScenePushed
  end

  def replace_top(new_scene)
    @old_instances.push @instances.pop
    push new_scene
  end

  def pop
    @old_instances.push @instances.pop
    @push_pop_operation = ScenePopped
  end

  def pop_until(type)
    pop_count = @instances.rindex { |v| v.type == type }
    pop_count = pop_count.nil? ? 0 : @instances.length - pop_count + 1
    @old_instances.concat @instances.pop(pop_count).reverse!
    @push_pop_operation = ScenePopped
  end

  def find(type)
    idx = @instances.rindex { |v| v.type == type }
    idx.nil? ? nil : @instances[idx]
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

  def instance; @instances.last; end

  def run
    if FileFinder.rpg2k_project? FileFinder.project_tree
      Player.push debug_flag ? Scene_Title.new : Scene_Logo.new
    else
      Player.push Scene_ProjectFinder.new
    end

    @reset_flag = false

    # Reset frames before starting
    Graphics.frame_reset

    until @instances.empty?
      inst = self.instance
      case @push_pop_operation
      when ScenePushed
        Graphics.push
        inst.start
        inst.transition_in
      when ScenePopped; inst.continue
      when SceneNop
      else raise 'invalid operation %d' % @push_pop_operation
      end

      @push_pop_operation = SceneNop
      while @push_pop_operation == SceneNop
        Player.update
        Graphics.update
        Audio.update
        Input.update
        inst.update
      end

      Graphics.update
      inst.suspend
      inst.transition_out

      @old_instances.each { |_| Graphics.pop }
      @old_instances.clear
    end
  end

  def pause; Audio.bgm_pause; end

  def resume
    Input.reset_keys
    Audio.bgm_resume
    Graphics.frame_reset
  end

  def update
    Graphics.fps_on_screen = !Graphics.fps_on_screen if Input.trigger? Input::TOGGLE_FPS

    # use debug output for log viewer
    # Output.take_screenshot
    Output.debug "Screenshot request from user." if Input.trigger? Input::TAKE_SCREENSHOT

    if Input.trigger? Input::LOG_VIEWER
      Player.find("Log Viewer").nil? ? Player.pop : Player.push(Scene_LogViewer.new)
    end

    Output.update

    if exit_flag
      @instances.clear
    elsif reset_flag
      @reset_flag = false
      Player.pop_until 'Title'
    end
  end

  attr_reader(:debug_flag, :hide_title_flag, :window_flag,
              :battle_test_flag, :battle_test_troop_id,
              :instances, :old_instances)

  attr_accessor :reset_flag, :exit_flag, :engine
end
