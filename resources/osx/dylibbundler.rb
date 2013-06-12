#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'open3'

VERSION = "0.4.1";

class Settings
  def isPrefixBundled(pre)
    pre.match(/.framework/) != nil or
      pre.match(/\/usr\/lib/) != nil or
      ignore_prefixes.find_index(pre) != nil
  end

  attr_accessor(:canOverwriteFiles, :canOverwriteDir,
                :canCreateDir, :bundleLibs, :destFolder,
                :inside_lib_path, :ignore_prefixes, :fixing_paths)

  def initialize()
    @canOverwriteDir = false
    @canOverwriteFiles = false
    @canCreateDir = false
    @bundleLibs = false
    @destFolder = nil
    @fixing_paths = []
    @ignore_prefixes =[]
    @inside_lib_path = "@executable_path/../Libraries"
  end
end

@settings = Settings.new

opts = OptionParser.new { |opt|
  opt.on('-x VALUE', '--fix-file VALUE', "<file to fix (executable or app plug-in)>") { |v|
    abs = File.absolute_path v
    @settings.fixing_paths.push abs
    if @settings.destFolder == nil
      @settings.destFolder = File.absolute_path(File.join File.dirname(abs), '../Libraries')
    end
  }
  opt.on('-b', '--bundle-deps') { |v|
    @settings.bundleLibs = v
  }
  opt.on('-p VALUE', '--install-path VALUE', "<'inner' path of bundled libraries (usually relative to executable, by default '@executable_path/../Libraries/')>") { |v|
    @settings.inside_lib_path = File.absolute_path v
  }
  opt.on('-i VALUE', '--ignore VALUE', "<location to ignore> (will ignore libraries in this directory)") { |v|
    @settings.ignore_prefixes.push File.absolute_path v
  }
  opt.on('-d VALUE', '--dest-dir VALUE', "<directory to send bundled libraries (relative to cwd)>") { |v|
    @settings.destFolder = File.absolute_path v
  }
  opt.on('-of', '--overwrite-files', "(allow overwriting files in output directory)") { |v|
    @settings.canOverwriteFiles = v
  }
  opt.on('-od', '--overwrite-dir', "(totally overwrite output directory if it already exists. implies --create-dir)") { |v|
    @settings.canOverwriteDir = v
    @settings.canCreateDir = v
  }
  opt.on('-cd', '--create-dir', "(creates output directory if necessary)") { |v|
    @settings.canCreateDir = v
  }
}
opts.parse!

class Dependency
  attr_accessor :filename, :prefix, :symlinks

  def initialize(path, s)
    @settings = s
    @symlinks = []

    res = File.absolute_path path
    if File.ftype(path) == "link"
      symlinks.push res
      res = File.readlink(res)
    end
    @filename = File.basename(res)
    @prefix = File.dirname(res)
  end

  def print()
    Kernel.print "\n * " + filename + " from " + prefix
    symlinks.each { |v|
      Kernel.print "    symlink --> " + v
    }
  end

  def original_path()
    File.join prefix, @filename
  end

  def install_path()
    File.join @settings.destFolder, @filename
  end

  def inner_path()
    File.join @settings.inside_lib_path, @filename
  end

  def mergeIfSameAs(d)
    if @filename == d.filename
      @symlinks = (@symlinks + d.symlinks).uniq!
      true
    else
      false
    end
  end

  def copyYourself()
    FileUtils.cp original_path, install_path

    raise "Cannot change library identity: " + install_path unless
      system("install_name_tool -id " + inner_path + " " + install_path)
  end

  def fixFileThatDependsOnMe(f)
    raise "Cannot fix dependencies of " + f unless
      system("install_name_tool -change " + original_path + " " + inner_path + " " + f)

    symlinks.each { |v|
      raise "Cannot fix dependencies of " + f unless
      system("install_name_tool -change " + File.join(prefix, v) + " " + inner_path + " " + f)
    }
  end
end

@deps = []

def addDependency(f)
  if f.match(/@executable_path/) != nil or not File.exists? f; return; end

  d = Dependency.new(f, @settings)

  if not File.exists? d.original_path; return; end

  if(@deps.find_index { |v| d.mergeIfSameAs(v) } == nil and not @settings.isPrefixBundled(d.prefix))
    @deps.push d
  end
end

def collectDependenciesLines(f)
  stdin, stdout = Open3.popen2e 'otool', '-L', f
  result = stdout.read
  raise "Cannot find file " + f + " to read its dependencies" unless
    result.match(/can't open file/) == nil and result.match(/No such file/) == nil

  result.lines.delete_if { |v|
    v[0] != "\t" or v.match(/.framework/) != nil
  }.map { |v| v[1, v.rindex(' (') - 1] }
end

def collectDependencies(f)
  print "."

  collectDependenciesLines(f).each { |v|
    print "."
    addDependency v
  }
end

def collectSubDependencies()
  while true
    dep_previos = @deps.length

    @deps.each { |d|
      print "."

      collectDependenciesLines(d.original_path).each { |v|
        addDependency v
      }
    }

    if(dep_previos == @deps.length); break; end
  end
end

def createDestDir()
  print "* Checking output directory " + @settings.destFolder

  if Dir.exists?(@settings.destFolder) and @settings.canOverwriteDir
    print "* Erasing old output directory " + @settings.destFolder
    FileUtils.rm_r @settings.destFolder
  end

  if @settings.canCreateDir
    print "* Creating output directory " + @settings.destFolder
    FileUtils.mkdir_p @settings.destFolder
  end
end

def changeLibPathsOnFile(f)
  print "\n* Fixing dependencies on " + f

  @deps.each { |v|
    v.fixFileThatDependsOnMe(f)
  }
end

def doneWithDeps_go()
  print "\n"
  @deps.each { |v| v.print }
  print "\n"

  if @settings.bundleLibs
    createDestDir()

    @deps.each { |v|
      v.copyYourself();
      changeLibPathsOnFile v.install_path
    }
  end

  @settings.fixing_paths.each { |v|
    changeLibPathsOnFile v
  }
end

if not @settings.bundleLibs and @settings.fixing_paths.empty?
  print opts.help
else
  print "* Collecting dependencies"

  @settings.fixing_paths.each { |v|
    collectDependencies(v)
  }
  collectSubDependencies()
  doneWithDeps_go()
end
