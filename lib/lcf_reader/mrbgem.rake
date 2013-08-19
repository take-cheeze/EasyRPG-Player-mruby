require 'fileutils'

MRuby::Gem::Specification.new('lcf_reader') { |spec|
  spec.license = 'BSD'
  spec.authors = 'take-cheeze'

  file "#{dir}/src/schema.cxx" => (Dir.glob("#{dir}/schema/*.json") << "#{dir}/to_cxx.rb") do |t|
    create_src_and_include_dir
    Dir.chdir("#{dir}") { `ruby #{dir}/to_cxx.rb #{dir}/schema #{t.name}` }
  end

  schema_obj = objfile_from_src("#{dir}/src/schema.cxx")
  @objs << schema_obj
  file schema_obj => "#{dir}/src/schema.cxx"
}
