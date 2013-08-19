def self.rand
  @random_src = Random.new Time.new.to_i if not defined? @random_src
  @random_src.rand
end
