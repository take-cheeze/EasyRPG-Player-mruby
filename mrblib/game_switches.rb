class Game_Switches; end

class << Game_Switches
  def data; $game_data.system.switch ||= []; end

  def [](idx)
    (data[idx - 1] || 0) != 0
  end

  def []=(idx, val)
    d = self.data
    prev_len = d.length
    d[idx - 1] = val ? 1 : 0

    if prev_len < idx
      $game_data.system.switch_count = idx
      d.map! { |v| v.nil? ? 0 : v }
    end

    val
  end
end
