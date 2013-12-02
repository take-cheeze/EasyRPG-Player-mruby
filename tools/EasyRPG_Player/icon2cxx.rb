#!/usr/bin/env ruby

require 'rubygems'
require 'devil'

script_path = File.expand_path(File.dirname(__FILE__))

Devil.with_image("#{script_path}/icon.png") do |img|
  img.rotate 180

  raise "width error: #{img.width}" unless img.width == 48
  raise "height error: #{img.height}" unless img.height == 48

  pixels = []
  img.to_blob.bytes.each_slice(4) do |p|
    pixels << ('0x' + p.map! { |v| '%02x' % v }.join)
  end
  rows = []
  pixels.each_slice(72) { |r| rows << r.join(', ') }

  IO.write "#{script_path}/icon.cxx", <<EOS
#include <cstdint>

extern uint32_t EasyRPGAppIcon[];

uint32_t EasyRPGAppIcon[] = {
  #{rows.join ",\n  "}
};
EOS
end
