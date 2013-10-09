class Game_Variables; end

class << Game_Variables
  def data; $game_data.system.variable ||= []; end

  def [](idx)
    data[idx - 1] || 0
  end

  def []=(idx, val)
    d = self.data
    prev_len = d.length
    d[idx - 1] = val

    if prev_len < idx
      $game_data.system.variable_count = idx
      d.map! { |v| v.nil? ? 0 : v } 
    end

    val
  end
end
