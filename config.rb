MRuby::Build.new do |conf|
  toolchain :gcc
  enable_debug

  # include the default GEMs
  conf.gembox 'default'

  ENV['PLAYER_BASE'] = File.expand_path '..'
  conf.gembox "#{ENV['PLAYER_BASE']}/player"

  conf.cc { |cc|
    com = cc.command.split ' '
    cc.command = com[0]
    cc.flags = com[1, com.length - 1].concat cc.flags
  }
  conf.cxx { |cxx|
    cxx.command = ENV['CXX'] || 'c++'
    cxx.flags = [ENV['CXXFLAGS'] || []]
    com = cxx.command.split ' '
    cxx.command = com[0]
    cxx.flags = com[1, com.length - 1].concat cxx.flags
  }

  # use C++ linker
  conf.linker { |linker|
    linker.command = conf.cxx.command
    linker.flags = conf.cxx.flags
  }

  conf.cxx.defines << 'USE_SDL=1' << "HAVE_SDL_MIXER=1"
  ['sdl2', 'freetype2', 'pixman-1', 'libpng', 'zlib'].each { |v|
    conf.cxx.flags += [`pkg-config #{v} --cflags`.chomp]
    conf.linker.flags += [`pkg-config #{v} --libs`.chomp]
  }
  conf.linker.libraries << 'SDL2_mixer'

  if `uname`.chomp.downcase == 'darwin'
    conf.cxx.include_paths << '/opt/local/include'
    conf.cc.include_paths << '/opt/local/include'
    conf.linker.library_paths << '/opt/local/lib'
    conf.linker.libraries << 'iconv'
  end

  # comment out this if line you want to use wine resources
  #conf.cxx.defines << 'HAVE_WINE=1' if Dir.exists? "#{ENV["HOME"]}/.wine"
end
