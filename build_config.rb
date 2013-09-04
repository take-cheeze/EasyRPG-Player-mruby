MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  # include the default GEMs
  conf.gembox 'default'

  ENV['PLAYER_BASE'] = File.expand_path '..'
  conf.gembox "#{ENV['PLAYER_BASE']}/player"

  conf.mrbc.compile_options += ' -g'

  conf.cc { |cc|
    com = cc.command.split ' '
    cc.command = com[0]
    cc.flags = com[1, com.length - 1].concat cc.flags
    cc.flags << "-DMRB_DEBUG=1"
    cc.include_paths << '/opt/local/include'
  }
  conf.cxx { |cxx|
    cxx.command = ENV['CXX'] || 'c++'
    cxx.flags = [ENV['CXXFLAGS'] || []]
    com = cxx.command.split ' '
    cxx.command = com[0]
    cxx.flags = com[1, com.length - 1].concat cxx.flags
    cxx.include_paths << '/opt/local/include'
    cxx.flags << "-DMRB_DEBUG=1"
  }

  # use C++ linker
  conf.linker { |linker|
    linker.command = conf.cxx.command
    linker.flags = conf.cxx.flags
    linker.library_paths << '/opt/local/lib'
  }

  conf.cxx.flags << '-DUSE_SDL=1' << "-DHAVE_SDL_MIXER=1"
  ['sdl', 'freetype2', 'pixman-1', 'libpng', 'zlib'].each { |v|
    conf.cxx.flags += [`pkg-config #{v} --cflags`.chomp]
    conf.linker.flags += [`pkg-config #{v} --libs`.chomp]
  }
  conf.linker.libraries << 'SDL_mixer' << 'iconv'
end
