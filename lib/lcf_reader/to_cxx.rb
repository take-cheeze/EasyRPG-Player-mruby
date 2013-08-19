#!/usr/bin/env ruby -Ku

require 'rubygems'
require 'json'

# usage> to_cxx.rb INPUT_DIRECTORY OUTPUT
raise "argument error" unless ARGV.length == 2

out = File.open(ARGV[1], "w")

out.write "#include <cstdlib>\n"
out.write "extern char const* LCF_SCHEMA_JSON_STRING[];\n"
out.write "char const* LCF_SCHEMA_JSON_STRING[] = {\n"

Dir.glob("#{ARGV[0]}/*.json") { |f|
  # check json
  out.write "  \"" + JSON.dump(JSON.parse(IO.read(f))).gsub("\"", "\\\"") + "\",\n\n"
}

out.write "  NULL,\n"
out.write "};\n"
