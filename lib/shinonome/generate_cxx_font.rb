#!/usr/bin/env ruby
# encoding: utf-8

FONT_SIZE = 12
EMPTY_CHAR = Array.new(FONT_SIZE, 0x0)

KanjiEncoding = "JIS_X0208"
HankakuEncoding = "JIS_X0201"

require 'rubygems'
require 'iconv'

def skip_until(f, regex)
  while(not f.eof?)
    l = f.readline().chomp
    ret = regex.match(l)
    return ret if ret
  end
  return false
end

class Glyph
  attr_reader :code, :is_full, :data

  def initialize(c, f, d)
    raise "type error" unless c.instance_of? Fixnum
    raise "type error" unless d.instance_of? Array

    @code = c
    @is_full = f
    @data = d
  end
end


def read_font(f, half, encoding)
  code = skip_until(f, /STARTCHAR\s+(\w+)/)
  return nil if not code

  skip_until(f, /BITMAP/)
  ret = Array.new(FONT_SIZE, 0)
  for y in 0...FONT_SIZE
    str = f.readline

    tmp = 0
    for x in 0...(half ? FONT_SIZE / 2 : FONT_SIZE)
      if str[x] == ?@;tmp |= 0x01 << x
      else; raise "unknown dot symbol: #{str[x]}" unless str[x] == ?.
      end
    end
    ret[y] = tmp
  end
  raise 'cannot end char' unless /ENDCHAR/.match(Iconv.conv('UTF-8', 'EUC-JP', f.readline()))

  c = code[1].hex
  if encoding == KanjiEncoding
    encoding = "CP932"

    j1 = (c >> 8) & 0xff
    j2 = c & 0xff

    s1 = (32 < j1 and j1 <= 94) ? (j1 + 1) / 2 + 112 : (j1 + 1) / 2 + 176
    s2 = (j1 & 0x01) == 1 ? j2 + 31 + j2 / 96 : j2 + 126

    c = ((s1 & 0xff) << 8) + s2
    code = [s1, s2].pack("CC")
  elsif encoding ==  HankakuEncoding
    raise "too big code: #{c}" unless c < 0x100
    return nil if 0xE0 <= c
    code = [c].pack('C')
    encoding = 'CP932'
  else
    code = (c < 0x100 ? [c] : [c & 0xff, (c >> 8) & 0xff]).pack("C*")
  end

  raise "size error" unless code.bytesize == (c < 0x100 ? 1 : 2)

  begin; code = Iconv.conv('UTF-32LE', encoding, code)
  rescue Iconv::IllegalSequence
    print "invalid code 0x%02x, 0x%02x\n" % [(c >> 8) & 0xff, c & 0xff]
    return false
  end

  raise "invalid code: #{c} #{code.bytes.to_a}" unless code.bytesize == 4

  return Glyph.new(code.unpack("V")[0], !half, ret)
end

def read_file(f, encoding, half)
  ret = {}
  while(true)
    font = read_font(f, half, encoding)
    ret[font.code] = font unless font.nil?
    return ret if f.eof?
  end
end

def write_all(f, sym, data)
  f.write <<EOS
#include "shinonome.hxx"

ShinonomeGlyph const #{sym}[#{data.size}] = {
EOS

  code_max = 0

  data.sort.each { |v|
    g = v[1]
    f.write "  { #{g.code}, #{g.is_full}, { #{g.data.join(", ")} } },\n"
    code_max = [g.code, code_max].max
  }
  f.write "};\n"

  code_max
end

# loading
print "Loading Lantin-1..."
latin = read_file(File.new('./latin1/font_src.bit', 'r'), "latin1", true)
print "done\n"

print "Loading Hankaku..."
hankaku = read_file(File.new('./hankaku/font_src_diff.bit', 'r'), HankakuEncoding, true)
print "done\n"

print "Loading Gothic..."
gothic = read_file(File.new('./kanjic/font_src.bit', 'r'), KanjiEncoding, false)
print "done\n"

print "Loading Mincho..."
mincho = read_file(File.new('./mincho/font_src_diff.bit', 'r'), KanjiEncoding, false)
print "done\n"

# generating
print "Generating Gothic..."
gothic_final = gothic.merge(hankaku).merge!(latin)
code_max = write_all(File.new("./src/gothic.cxx", "w"), "SHINONOME_GOTHIC", gothic_final)
print "done\n"

print "Generating Mincho..."
code_max = [write_all(File.new("./src/mincho.cxx", "w"), "SHINONOME_MINCHO", mincho), code_max].max
print "done\n"

# header
print "Generating Header..."
File.new('./include/shinonome.hxx', 'w').write <<EOS
#ifndef _INC_SHINONOME_HXX_
#define _INC_SHINONOME_HXX_

#include <cstdint>

struct ShinonomeGlyph {
	uint#{code_max < 0x10000 ? 16 : 32}_t code;
	bool is_full;
	uint16_t data[#{FONT_SIZE}];
};

extern ShinonomeGlyph const SHINONOME_GOTHIC[#{gothic_final.size}];
extern ShinonomeGlyph const SHINONOME_MINCHO[#{mincho.size}];

#endif // _INC_SHINONOME_HXX_
EOS
print "done\n"
