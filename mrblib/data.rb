# This file is part of EasyRPG Player.
#
# EasyRPG Player is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# EasyRPG Player is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EasyRPG Player. If not, see <http://www.gnu.org/licenses/>.

def assert(exp); raise "assertion failed" unless exp; end

module Data end

class << Data
  def clear
  end

  def load_ldb(f)
    @ldb = LCF::LcfFile.new f
  end

  def load_lmt(f)
    @lmt = LCF::LcfFile.new f
    def @lmt.start
      root 2
    end
  end

  def treemap; @lmt; end

  def method_missing(sym)
    @ldb[sym]
  end
end
