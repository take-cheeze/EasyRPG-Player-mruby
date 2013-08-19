class Scene
  attr_reader :type

  def self.create_null_scene; Scene.new nil end

  def initialize(type) @type = type; end

  def transition_in; Graphics.transition_2k Graphics::TransitionFadeIn, 12; end
  def transition_out; Graphics.transition_2k Graphics::TransitionFadeOut, 12, true; end

  def start; end
  def continue; end
  def resume; end
  def suspend; end
  def update; end

  SceneNop = 0
  ScenePushed = 1
  ScenePopped = 2

  @@instance = nil
  @@old_instances = []
  @@instances = []
  @@push_pop_operation = SceneNop;

  def self.instance; @@instance; end
  def self.old_instances; @@old_instances; end

  def main_function
    case @@push_pop_operation
    when ScenePushed; start
    when ScenePopped; continue
    when SceneNop
    else raise 'invalid operation %d' % @@push_pop_operation
    end

    @@push_pop_operation = SceneNop

    while @@instance == self
      Player.update
      Graphics.update
      Audio.update
      Input.update
      update
    end

    Graphics.update
    suspend
    transition_out

    case @@push_pop_operation
    when ScenePushed; Graphics.push
    when ScenePopped
    when SceneNop
    else raise 'invalid operation %d' % @@push_pop_operation
    end
  end

  def self.push(new_scene, pop_stack_top = false)
    if pop_stack_top
      @@old_instances.push @@instances.pop
    end

    @@instances.push new_scene
    @@instance = new_scene
    @@push_pop_operation = ScenePushed
  end

  def self.pop
    @@old_instances.push @@instances.pop

    if @@instances.empty?
      push create_null_scene
    else
      @@instance = @instances.back
    end

    @@push_pop_operation = ScenePopped
  end

  def self.pop_until(type)
    pop_count = @@instances.reverse.find_index { |v| v.type == type }
    pop_count = pop_count.nil? ? 0 : pop_count + 1

    @@old_instances.concat @@instances.pop(pop_count).reverse!
  end

  def self.find(type) @@instances.reverse.find { |v| v.type == type } end
end
