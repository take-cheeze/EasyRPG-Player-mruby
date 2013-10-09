class Scene
  attr_reader :type

  def initialize(type) @type = type; end

  def transition_in; Graphics.transition_2k Graphics::TransitionFadeIn, 12; end
  def transition_out; Graphics.transition_2k Graphics::TransitionFadeOut, 12, true; end

  def start; end
  def continue; end
  def resume; end
  def suspend; end
  def update; end
end
