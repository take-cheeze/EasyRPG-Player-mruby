class Scene_ProjectFinder < Scene
  def initialize
    super "Project Finder"
  end

  def register_project_base_path(ini, section)
    app = Registry.read_string_value(Registry::HKEY_LOCAL_MACHINE,
                                     "Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\#{ini}.exe",
                                     'Path')
    return unless app

    assert FileFinder.exists? app

    base_path = Registry.read_string_value(FileFinder.make_path(app, ini + ".ini"),
                                           section, "ProjectBasePath")
    @root.push Entry.new('Project Base Path %s (%s)' % [ini, base_path], base_path) if
      not base_path.nil? and FileFinder.exists?(base_path)
  end

  COLUMN_MAX = 25
  ROW_MAX = 18

  class Entry
    def initialize(n, p, is_project = nil)
      @path, @is_project = p, is_project
      @cursor, @offset = 0, 0

      if is_project.nil?
        @parent, @name = nil, n
        assert ! project?
      else
        @parent, @name = n, p + (is_project ? '' : '/')
      end
      assert ! fullpath.empty?
    end

    def fullpath
      @parent.nil? ? FileFinder.fullpath(@path) : FileFinder.make_path(@parent.fullpath, @path)
    end

    attr_accessor :cursor, :offset
    attr_reader :name, :path, :parent

    def sprite
      unless @sprite
        @sprite = Sprite.new
        @children = create_children
        @sprite.bitmap = @children.empty? ? nil : Scene_ProjectFinder.create_bitmap(@children)
        @sprite.visible = false
      end
      @sprite
    end

    def children
      sprite
      return @children
    end

    def project?
      @is_project = FileFinder.rpg2k_project? fullpath if @is_project.nil?
      @is_project
    end

    def create_children
      ret = []
      dir_base = fullpath
      FileFinder.directory_members(dir_base, FileFinder::DIRECTORIES).each do |k,v|
        ret.push Entry.new self, v, FileFinder.rpg2k_project?(FileFinder.make_path(dir_base, v)) unless
          FileFinder.directory_members(FileFinder.make_path(dir_base, v), FileFinder::DIRECTORIES).empty?
      end
      ret
    end
  end

  def update
    if Input.trigger?(Input::DECISION) or Input.trigger?(Input::RIGHT); select_entry
    elsif Input.repeat?(Input::UP); self.index -= 1
    elsif Input.repeat?(Input::DOWN); self.index += 1
    elsif Input.trigger?(Input::CANCEL) or Input.trigger?(Input::LEFT); to_parent
    end
  end

  def index; @current_entry.nil? ? @root_index : @current_entry.cursor; end
  def index=(idx)
    idx = (idx + children_count) % children_count
    @current_entry.nil? ? @root_index = idx : @current_entry.cursor = idx
    self.offset = [0, self.index - ROW_MAX + 1, [self.offset, self.index].min].max

    assert self.index < self.children_count

    @cursor.y = @font_size * (self.index - self.offset + 1) - 1
    self.sprite.src_rect = Rect.new(0, @font_size * self.offset,
                                    @font_size * COLUMN_MAX, @font_size * ROW_MAX)
  end

  def children_count; @current_entry.nil? ? @root.length : @current_entry.children.length end

  def offset; @current_entry.nil? ? @root_offset : @current_entry.offset end
  def offset=(v) @current_entry.nil? ? @root_offset = v : @current_entry.offset = v end

  def sprite; @current_entry.nil? ? @root_sprite : @current_entry.sprite end

  def self.create_bitmap(list)
    assert !list.empty?

    font_size = 12 # Font.shinonome.pixel_size
    ret = Bitmap.new font_size * COLUMN_MAX, font_size * list.length

    list.each_with_index do |v,i|
      Font.default_color = Color.new(v.project? ? 255 : 0, 0, 0, 255)
      ret.draw_text 0, font_size * i, v.name
    end

    ret
  end

  def select_entry
    assert index < children_count

    sprite.visible = false
    @current_entry = (@current_entry.nil? ? @root : @current_entry.children)[index]

    if @current_entry.project?
      FileFinder.project_path = @current_entry.fullpath
      Player.push Scene_Title.new
      to_parent
    elsif @current_entry.children.empty?
      to_parent # return to parent
    else
      sprite.x, sprite.y = @font_size, @font_size
      sprite.visible = true
      self.index = index
    end
  end

  def to_parent
    if @current_entry.nil?
      Player.exit_flag = true
    else
      @current_entry.sprite.visible = false
      @current_entry = @current_entry.parent
      sprite.visible = true
      self.index = index
    end
  end

  def start
    @current_entry = nil

    @root = []
    @root_index, @root_offset = 0, 0
    @root_sprite, @background, @cursor = nil, nil, nil

    @font_size = 0

    @root.push Entry.new(". (#{FileFinder.fullpath('.')})", '.')

    home = Utils.home_path
    @root.push Entry.new('HOME (%s)' % home, home) if not home.nil?

    Utils.drives.each do |k,v|
      @root.push Entry.new(k.to_s + v.empty? ? '' : ' (#{v})', k.to_s)
    end

    register_project_base_path "RPG2000T", "RPG2000"
    register_project_base_path "RPG2000" , "RPG2000"

    @root = @root.reject { |v| v.children.empty? }

    @font_size = 12 # @font.pixel_size

    @root_sprite, @background, @cursor = Sprite.new, Sprite.new, Sprite.new

    @background.bitmap = Bitmap.new SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT
    @background.bitmap.fill_rect @background.bitmap.rect, Color.new(255, 255, 255, 255)
    @background.z = -1000

    @root_sprite.bitmap = Scene_ProjectFinder.create_bitmap @root
    @root_sprite.x, @root_sprite.y = @font_size, @font_size
    @root_sprite.src_rect = Rect.new 0, 0, @font_size * COLUMN_MAX, @font_size * ROW_MAX

    cursor_bmp = Bitmap.new @font_size * COLUMN_MAX + 4, @font_size + 2
    blue = Color.new 0, 0, 255, 255
    # top
    cursor_bmp.fill_rect Rect.new(0, 0, cursor_bmp.width, 1), blue
    # left
    cursor_bmp.fill_rect Rect.new(0, 0, 1, cursor_bmp.height), blue
    # right
    cursor_bmp.fill_rect Rect.new(cursor_bmp.width - 1, 0, 1, cursor_bmp.height), blue
    # bottom
    cursor_bmp.fill_rect Rect.new(0, cursor_bmp.height - 1, cursor_bmp.width, 1), blue

    @cursor.bitmap = cursor_bmp
    @cursor.x = @font_size - 2
    @cursor.y = @font_size - 1
  end
end
