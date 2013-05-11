#!/usr/bin/env ruby

require 'rubygems'
require 'devil'

script_path = File.expand_path(File.dirname(__FILE__))

BLACK = [0x00, 0x00, 0x00, 0xff]
WHITE = [0xff, 0xff, 0xff, 0xff]

Devil.with_image(script_path + '/exfont.png') { |img|
  img.rotate 180

  raise "width error" unless img.width == 12 * 13
  raise "height error" unless img.height == 12 * 4

  blb = img.to_blob.bytes
  glyphs = []

  for y in 0...4
    for x in 0...13
      print "%d, %d\n" % [x, y]
      glyphs.push([])

      for pix_y in 0...12
        bitmap = 0

        for pix_x in 0...12
          pixel = blb[4 * (img.width * (y * 12 + pix_y) + (x * 12 + pix_x)), 4]

          if pixel == BLACK
            print "00"
          else
            print "11"
            raise "invalid color" unless pixel == WHITE
          end

          bitmap |= (pixel == WHITE ? 1 : 0) << pix_x
        end

        glyphs.last.push(bitmap)

        print "\n"
      end
    end
  end

  IO.write script_path + '/exfont.cxx', <<EOS
#include "exfont.hxx"

uint16_t const EASYRPG_EXFONT[26 * 2][12] = {
#{glyphs.map { |v| "{ #{v.join(',')} }" }.join(",\n")}
};
EOS

  IO.write script_path + '/exfont.hxx', <<EOS
#ifndef EASYRPG_EXFONT_HXX
#define EASYRPG_EXFONT_HXX

#include <stdint.h>

extern uint16_t const EASYRPG_EXFONT[26 * 2][12];

#endif
EOS
}
