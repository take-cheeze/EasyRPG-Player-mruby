assert('Shinonome.empty_glyph') {
  g = Shinonome.empty_glyph
  g.code == 0 and g.full? and g.data.reduce(true) { |p,v| p and v == 0 }
}
