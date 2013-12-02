require 'fileutils'

MRuby::Gem::Specification.new 'EasyRPG_Player' do |spec|
  spec.license = 'GPL2'
  spec.authors = 'EasyRPG Developer Team'

  Dir.glob("#{dir}/src/binding/*.cpp").sort.each { |v|
    @objs << objfile_from_src(v)
  }

  # convert icon data to c++ code
  player_exec_base = "#{dir}/tools/EasyRPG_Player"
  icon_file = "#{player_exec_base}/icon.cxx"
  task(:clean) { FileUtils.rm_f [icon_file] }
  file icon_file => ["#{player_exec_base}/icon.png", "#{player_exec_base}/icon2cxx.rb"] do |t|
    Dir.chdir(player_exec_base) { `#{player_exec_base}/icon2cxx.rb` }
  end
  file "#{player_exec_base}/main.cpp" => icon_file
  @objs << objfile_from_src(icon_file)

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
