require 'rubygems'
require 'net/http'
require 'libarchive'
require 'fileutils'

MRuby::Gem::Specification.new('utf8proc') do |spec|
  spec.license = 'MIT'
  spec.authors = ''
  version = "1.1.6"

  utf8proc_dir = "#{dir}/utf8proc-v#{version}"
  header = "#{dir}/include/utf8proc.h"
  src = "#{utf8proc_dir}/utf8proc.c"

  task :clean do
    FileUtils.rm_rf [utf8proc_dir, header]
  end

  file header do |t|
    create_src_and_include_dir

    Dir.chdir("#{dir}") do
      Net::HTTP.start('www.public-software-group.org') do |http|
        file = "/pub/projects/utf8proc/v#{version}/utf8proc-v#{version}.tar.gz"
        Archive.read_open_memory(http.get(file).body,
                                 Archive::COMPRESSION_GZIP, Archive::FORMAT_TAR) do |arch|
          while ent = arch.next_header
            if ent.directory?
              Dir.mkdir path unless File.directory? ent.pathname
            else
              FileUtils.mkdir_p File.dirname ent.pathname
              File.open(ent.pathname, 'w+') do |f|
                arch.read_data { |d| f.write d }
              end
            end
          end
        end
      end
    end

    FileUtils.copy "#{utf8proc_dir}/utf8proc.h", header
  end
  file src => header

  utf8proc_obj = objfile_from_src src
  objs << utf8proc_obj
  file utf8proc_obj => src
  file utf8proc_obj => header
end
