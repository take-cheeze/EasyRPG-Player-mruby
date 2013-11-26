require 'fileutils'

MRuby::Gem::Specification.new('shinonome') { |spec|
  spec.license = 'public domain'
  spec.authors = 'take-cheeze'

  file "#{dir}/include/shinonome.hxx" => ["#{dir}/generate_cxx_font.rb",
                                          "#{dir}/latin1/font_src.bit",
                                          "#{dir}/hankaku/font_src_diff.bit",
                                          "#{dir}/kanjic/font_src.bit",
                                          "#{dir}/mincho/font_src_diff.bit"] do |t|
    create_src_and_include_dir
    Dir.chdir("#{dir}") { `#{dir}/generate_cxx_font.rb` }
  end

  ['mincho', 'gothic'].each { |v|
    file "#{dir}/src/#{v}.cxx" => ["#{dir}/include/shinonome.hxx"]
    @objs << objfile_from_src("#{dir}/src/#{v}.cxx")
  }

  file "#{dir}/src/shinonome.cxx" => "#{dir}/include/shinonome.hxx"
}
