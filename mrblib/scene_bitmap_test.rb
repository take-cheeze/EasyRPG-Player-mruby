class Scene_BitmapTest < Scene
	def initialize
    super 'Bitmap Test'

    @rgba = Sprite.new
    @rgba.bitmap = Bitmap.new 40, 10
    @rgba.y = 0
    assert @rgba.bitmap.get_pixe(0, 0) == Color.new(0, 0, 0, 0)

    @rgba.bitmap.fill Rect.new( 0, 0, 10, 10), Color.new(255, 0, 0, 255)
    @rgba.bitmap.fill Rect.new(10, 0, 10, 10), Color.new(0, 255, 0, 255)
    @rgba.bitmap.fill Rect.new(20, 0, 10, 10), Color.new(0, 0, 255, 255)
    @rgba.bitmap.fill Rect.new(30, 0, 10, 10), Color.new(255, 255, 255, 255)
    assert @rgba.bitmap.get_pixel( 0, 0) == Color.new(255, 0, 0, 255)
    assert @rgba.bitmap.get_pixel(10, 0) == Color.new(0, 255, 0, 255)
    assert @rgba.bitmap.get_pixel(20, 0) == Color.new(0, 0, 255, 255)
    assert @rgba.bitmap.get_pixel(30, 0) == Color.new(255, 255, 255, 255)

    @text = Sprite.new
    Font.default_color = Color.new 255, 255, 255, 255
    @text.y = 10
    @text.bitmap = Bitmap.new 100, 12
    @text.bitmap.fill Rect.new(0, 0, 100, 12), Color.new(0, 0, 255, 255)
    @text.bitmap.draw_text_2k 0, 0, "Hello World!"
  end

  def update
    if Input.any_pressed?
      Output.take_screenshot
      Player.exit_flag = true
    end
  end
end
