MRuby::Build.new do |conf|
  # load specific toolchain settings
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
    cxx.defines << 'BOOST_NO_CXX11_SMART_PTR'
  }

  # use C++ linker
  conf.linker { |linker|
    linker.command = conf.cxx.command
    linker.flags = conf.cxx.flags
  }

  conf.cxx.flags << '-DUSE_SDL=1' << "-DHAVE_SDL_MIXER=1"
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
end
