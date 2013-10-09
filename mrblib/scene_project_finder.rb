class Scene_ProjectFinder < Scene
  def initialize
    super "Project Finder"

    @current_entry = nil

    @root = []
    @root_index = 0
    @root_offset = 0

    @root_sprite = nil
    @background = nil
    @cursor = nil

    @font_size = 0
    @font = nil

    @root.push Entry.new('. (%s)' % FileFinder.fullpath('.'), '.')

    home = Utils.home_path
    @root.push Entry.new('HOME (%s)' % home, home) if not home.nil?

    Utils.drives.each { |k,v|
      @root.push Entry.new(k.to_s + v.empty? ? '' : '(%s)' % v, k.to_s)
    }

    register_project_base_path p, "RPG2000T", "RPG2000" if p = app_path("RPG2000T")
    register_project_base_path p, "RPG2000" , "RPG2000" if p = app_path("RPG2000")

    @root.delete_if { |v| v.no_children? }
  end

  def register_project_base_path(app_path, ini, section)
    assert FileFinder.exists app_path

    base_path = Registry.read_string_value(FileFinder.make_path(app_path, ini + ".ini"),
                                           section, "ProjectBasePath")
    @root.push Entry.new('Project Base Path %s (%s)' % [ini, base_path], base_path) if
      not base_path.nil? and FileFinder.exists(base_path)
  end

  COLUMN_MAX = 25
  ROW_MAX = 18

  class Entry
    def initialize(n, p, is_project = nil)
      if is_project.nil?
        @name = n
        @path = FileFinder.fullpath p
        @cursor, @offset = 0, 0
        @is_project = nil
      else
        @parent = n
        @name = p + is_project ? '' : '/'
        @cursor, @offset = 0, 0
        @is_project = is_project
      end

      assert ! project?
      assert ! path.empty?
    end

    def fullpath
      parent.nil? ? FileFinder.fullpath(@path) : FileFinder.make_path(parent.fullpath, @path)
    end

    attr_accessor :parent, :cursor, :offset
    attr_reader :name, :path

    def sprite
      if @sprite.bitmap.nil?
        @children = create_children
        @sprite.bitmap = @children.empty? ? Bitmap.new(1, 1) : create_bitmap(@children)
        @sprite.visible = false
      end
      @sprite
    end

    def children
      sprite
      return @children
    end

    def project?
      if @is_project.nil?
        mem = FileFinder.directory_members(fullpath, FileFinder::DIRECTORIES).members
        @is_project = FileFinder.rpg2k_project?(mem)
      end
      @is_project
    end

    def create_children
      ret = []
      dir = f.GetDirectoryMembers(fullpath(), FileFinder::DIRECTORIES)

      dir.members.each { |k,v|
        d = FileFinder.directory_members(FileFinder.make_path(dir.base, v),
                                         FileFinder::DIRECTORIES)

        if not d.members.empty?
          mem = FileFinder.directory_members(FileFinder.make_path(dir.base, v),
                                             FileFinder::FILES).members
          ret.push Entry.new(self, v, FileFinder.rpg2k_project?(mem))
        end
      }

      ret
    end
  end

  def app_path(exec)
    Registry.read_string_value(Registry::HKEY_LOCAL_MACHINE,
                               "Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\" + exec + '.exe',
                               'Path')
  end

  def update
    if Input.trigger?(Input::DECISION) or Input.trigger?(Input::RIGHT); select_entry
    elsif Input.repeat?(Input::UP); self.index = current_index - 1
    elsif Input.repeat?(Input::DOWN); self.index = current_index + 1
    elsif Input.trigger?(Input::CANCEL) or Input.trigger?(Input::LEFT); to_parent
    end
  end

  def index=(v)
    self.index = (idx + current_children_count) % children_count
    self.offset = [0, self.index - ROW_MAX + 1, [self.offset, self.index].min].max

    assert self.index < self.children_count

    @cursor.y = @font_size * (self.index - self.offset + 1) - 1
    self.sprite.src_rect = Rect.new(0, @font_size * self.offset,
                                    @font_size * COLUMN_MAX, @font_size * ROW_MAX)
  end

  def children_count
    @current_entry.nil? ? @root.length : @current_entry.children.length
  end

  def index
    @current_entry.nil? ? @root_index : @current_entry.index
  end
  def index=(v)
    @current_entry.nil? ? @root_index = v : @current_entry.index = v
  end

  def offset
    @current_entry.nil? ? @root_offset = v : @current_entry.offset = v
  end
  def offset=(v)
    @current_entry.nil? ? @root_offset = v : @current_entry.offset = v
  end

  def sprite
    @current_entry.nil? ? @root_sprite : @current_entry.sprite
  end

  def create_bitmap(list)
    assert !list.empty?

    @font_size = Font.shinonome.pixel_size
    width = @font_size * COLUMN_MAX
    ret = Bitmap.new width, @font_size * list.length
    ret.font = Font.shinonome

    list.each_with_index { |v,i|
      Font.default_color = v.project? ? Color.new(255, 0, 0, 255) : Color.new(0, 0, 0, 255)
      y = font_size_ * i
      ret.draw_text 0, y, v.name

      # fill with .... if directory name is too long
      if ret.text_size(v.name).width > width
        ret.fill Rect.new(width - @font_size * 2, y, @font_size * 2, @font_size), Color.new(0, 0, 0, 0)
        ret.draw_text width - @font_size * 2, y, "...."
      end
    }

    ret
  end

  def select_entry
    assert index < children_count

    sprite.visible = false
    @current_entry = (@current_entry.nil? ? @root : @current_entry.children)[index]

    if @current_entry.project?
      $project_path = @current_entry.fullpath
      Player.push Scene_Title.new
      to_parent
    elsif @current_entry.children.empty?
      to_parent # return to parent
    else
      current_sprite.x = @font_size
      current_sprite.y = @font_size
      current_sprite.visible = true
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
    @font = Font.shinonome
    @font_size = @font.pixel_size

    @root_sprite = Sprite.new
    @background = Sprite.new
    @cursor = Sprite.new

    @background.bitmap = Bitmap.new SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT, Color.new(255, 255, 255, 255)
    @background.z = -1000

    @root_sprite.bitmap = create_bitmap @root
    @root_sprite.x = @font_size
    @root_sprite.y = @font_size
    @root_sprite.src_rect = Rect.new 0, 0, @font_size * COLUMN_MAX, @font_size * ROW_MAX

    cursor_bmp = Bitmap.new @font_size * COLUMN_MAX + 4, @font_size + 2
    blue = Color.new 0, 0, 255, 255
    # top
    cursor_bmp.fill Rect.new(0, 0, cursor_bmp.width, 1), blue
    # left
    cursor_bmp.fill Rect.new(0, 0, 1, cursor_bmp.height), blue
    # right
    cursor_bmp.fill Rect.new(cursor_bmp.width - 1, 0, 1, cursor_bmp.height), blue
    # bottom
    cursor_bmp.fill Rect.new(0, cursor_bmp.height - 1, cursor_bmp.width, 1), blue

    @cursor.bitmap = cursor_bmp
    @cursor.x = @font_size - 2
    @cursor.y = @font_size - 1
  end
end
