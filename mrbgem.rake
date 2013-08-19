MRuby::Gem::Specification.new('EasyRPG_Player') { |spec|
  spec.license = 'GPL2'
  spec.authors = 'EasyRPG Developer Team'

  Dir.glob("#{dir}/src/binding/*.cpp").sort.each { |v|
    @objs << objfile_from_src(v)
  }

  spec.cxx.flags << '-DUSE_SDL=1'
  ['sdl', 'freetype2', 'pixman-1', 'libpng', 'zlib'].each { |v|
    spec.cxx.flags << `pkg-config #{v} --cflags`.chomp
    spec.linker.flags << `pkg-config #{v} --libs`.chomp
  }

  file "#{dir}/src/font.cpp" => "#{dir}/lib/shinonome/include/shinonome.hxx"
  file "#{dir}/src/text.cpp" => "#{dir}/lib/exfont/include/exfont.hxx"

  ['lcf_reader', 'shinonome', 'exfont', 'utf8proc', 'mruby-onig-regexp'
  ].each { |v| spec.add_dependency v }

  spec.bins = ['EasyRPG_Player']
}
