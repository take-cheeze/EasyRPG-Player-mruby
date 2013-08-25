class Scene_LogViewer < Scene
  def initialize
    super 'Log Viewer'
    @cursor_index, @cursor_offset = 0, 0
    @use_local_time = true
    @line_scroll_counter = 0
  end

  # generate bitmaps from Output buffer
  def start
    @line_repeat = Sprite.new
    @line_repeat.visible = false

    @screenshot = Sprite.new
    @screenshot.visible = false
    @screenshot.z = 100 # give higher priority than log lines

    @screenshot_time = Sprite.new
    @screenshot_time.visible = false
    @screenshot_time.z = 200

    @font = Font.shinonome
    @font_size = @font.pixel_size

    @row_max = SCREEN_TARGET_HEIGHT / @font_size - 2
    @col_max = SCREEN_TARGET_WIDTH / @font_size - 1

    cursor_bmp = Bitmap.new @font_size * @col_max + 4, @font_size + 2
    blue = Color.new 0, 0, 255, 255
    # top
    cursor_bmp.fill Rect.new(0, 0, cursor_bmp.width, 1), blue
    # left
    cursor_bmp.fill Rect.new(0, 0, 1, cursor_bmp.height), blue
    # right
    cursor_bmp.fill Rect.new(cursor_bmp.width - 1, 0, 1, cursor_bmp.height), blue
    # bottom
    cursor_bmp.fill Rect.new(0, cursor_bmp.height - 1, cursor_bmp.width, 1), blue
    @cursor = Sprite.new
    @cursor.bitmap = cursor_bmp
    @cursor.x = @font_size - 2

    # white background
    @background = Sprite.new
    @background.bitmap = Bitmap.new(SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT,
                                    Color.new(255, 255, 255, 255))
    @background.z = -100
    @background.visible = true

    @buffer_cache = Output.buffer
    @lines = Array.new @buffer_cache.length

    self.cursor_index = @lines.length - 1
  end

  def update
    line = @buffer_cache[@cursor_index]

    if @screenshot.visible and Input.trigger? Input::CANCEL
      @screenshot.visible = false
      @screenshot_time.visible = false
      self.cursor_index = @cursor_index
    elsif Input.trigger? Input::DECISION and not line[:screenshot].nil? and FileFinder.exists(line[:screenshot])
      hide_lines

      @screenshot.visible = true
      @screenshot.bitmap = ImageIO.read_png line[:screenshot], false

      time_str = time_string line
      if screenshot_time.bitmap.nil?
        time_size = @font.size time_str
        @screenshot_time.bitmap = Bitmap.new time_size.width + 1, time_size.height + 1
      else; @screenshot_time.bitmap.clear; end

      Font.default_color = Color.new 0, 0, 0, 255
      @screenshot_time.bitmap.draw_text 1, 1, time_str
      Font.default_color = Color.new 255, 255, 255, 255
      @screenshot_time.bitmap.draw_text 0, 0, time_str
      @screenshot_time.visible = true
    elsif Input.trigger? Input::CANCEL # exit log viewer
      Scene.pop
    elsif Input.repeat? Input::DOWN
      self.cursor_index = @cursor_index + 1
    elsif Input.repeat? Input::UP
      self.cursor_index = @cursor_index - 1
    elsif @enable_line_scroll
      repeat_blank = @font_size * 5

      s = @lines[@cursor_index]
      src_rect = s.src_rect
      @line_scroll_counter %= (s.bitmap.width + repeat_blank)
      src_rect.x = @line_scroll_counter
      @line_scroll_counter += 1
      s.src_rect = src_rect

      repeat_x = [0, [s.bitmap.width - src_rect.x + repeat_blank, @font_size * @col_max].min].max

      @line_repeat.visible = true
      @line_repeat.x = @font_size + repeat_x
      @line_repeat.y = s.y
      @line_repeat.src_rect =
        Rect.new(0, 0, [0, @font_size * @col_max - repeat_x].max, @font_size)
    end
  end

  def create_line(msg)
    line = generate_line msg
    bmp = Bitmap.new @font.size(line).width, @font.pixel_size
    Font.default_color = Output.type_color msg[:type]
    bmp.draw_text 0, 0, line
    bmp
  end

  def generate_line(msg)
    '%s %s %s' % [Output.type_string(msg[:type])[0], msg[:time], msg[:message]]
  end

  def hide_lines; @lines.each { |v| v.visible = false if not v.nil? }; end

  def cursor_index=(idx)
    @cursor_index = (idx + @lines.length) % lines.length
    @cursor_offset = [0, @cursor_index - @row_max + 1, [@cursor_offset, @cursor_index].min].max

    hide_lines

    # set cursor position
    @cursor.y = @font_size * (@cursor_index - @cursor_offset + 1) - 1

    # show and set position of active lines
    for i in 0...[@row_max, @lines.length - @cursor_offset].min
      buf = @buffer_cache[@cursor_offset + i]
      if @lines[@cursor_index + i].nil?
        @lines[@cursor_index + i] = Sprite.new
        @lines[@cursor_index + i].bitmap = create_line(buf)
      end
      s = @lines[@cursor_index + i]

      s.visible = true
      s.x = @font_size
      s.y = @font_size * (i + 1)
      s.src_rect = Rect.new 0, 0, @font_size * @col_max, @font_size

      if @cursor_offset + i == @cursor_index
        @enable_line_scroll = @font.size(generate_line buf).width > @font_size * @col_max
        @line_scroll_counter = 0
        @line_repeat.bitmap = s.bitmap
      end
    end
  end
end
