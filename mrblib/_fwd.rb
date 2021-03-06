class Game_Unit
end

class Game_Battler
end

class Window_Base < Window
end

class Window_Selectable < Window_Base
end

class Window_Item < Window_Selectable
end

class Window_Skill < Window_Selectable
end

def assert(exp); raise "assertion failed" unless exp; end

class String
  def %(args)
    if args.class == Array
      return sprintf(self, *args)
    else
      return sprintf(self, args);
    end
  end
end

class Hash
  def method_missing(sym, *args)
    case args.length
    when 0
      return self[sym]
    when 1
      name = sym.to_s
      if name[-1] == ?=
        return self[name[0, name.length - 1].to_sym] = args[0]
      end
    end
    BasicObject.method_missing(sym, *args)
  end
end

class Array
  alias :pop_once :pop

  def pop(n = nil)
    return pop_once if n.nil?
    ret = []
    for _ in 0...n; ret.push pop_once; end
    ret
  end
end
