module LCF
  class Array2d
    def each(&block)
      self.keys.each { |v| block.call v, self[v] }
      self
    end
  end
end
