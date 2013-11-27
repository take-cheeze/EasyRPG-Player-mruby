require 'fileutils'

MRuby::Gem::Specification.new('exfont') { |spec|
  spec.license = 'GPL2'
  spec.authors = 'EasyRPG Developer Team'

  task :clean do
    FileUtils.rm_f ["#{dir}/src/exfont.cxx", "#{dir}/include/exfont.hxx"]
  end

  file "#{dir}/include/exfont.hxx" => ["#{dir}/exfont.png", "#{dir}/exfont2cxx.rb"] do |t|
    create_src_and_include_dir
    Dir.chdir("#{dir}") { `#{dir}/exfont2cxx.rb` }
  end
  file "#{dir}/src/exfont.cxx" => ["#{dir}/include/exfont.hxx"]

  exfont_obj = objfile_from_src("#{dir}/src/exfont.cxx")
  @objs << exfont_obj
  file exfont_obj => "#{dir}/src/exfont.cxx"
}
