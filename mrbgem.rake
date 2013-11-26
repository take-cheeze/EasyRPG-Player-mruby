MRuby::Gem::Specification.new 'EasyRPG_Player' do |spec|
  spec.license = 'GPL2'
  spec.authors = 'EasyRPG Developer Team'

  Dir.glob("#{dir}/src/binding/*.cpp").sort.each { |v|
    @objs << objfile_from_src(v)
  }

  file "#{dir}/src/font.cpp" => "#{dir}/lib/shinonome/include/shinonome.hxx"
  file "#{dir}/src/text.cpp" => "#{dir}/lib/exfont/include/exfont.hxx"

  ['binder', 'lcf_reader', 'shinonome', 'exfont', 'utf8proc'
  ].each { |v| spec.add_dependency v }

  spec.bins = ['EasyRPG_Player']

  task "#{dir}/doc" => ["#{dir}/src/Doxyfile"] do
    Dir.chdir dir do
      `doxygen ./Doxyfile`
    end
  end
end
