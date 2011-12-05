###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor Test Suite
# Classes::     
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/21 15:25:08 $
#
###############################################################################

require 'test/unit'

$:.push '../lib'

# $:.push '../bin'

class TS_All
  def TS_All.suite
    suite = Test::Unit::TestSuite.new "Hotspot Editor"
    Object.constants.sort.each do |k|
      next unless /^TC_/.match k
      constant = Object.const_get(k)
      if constant.kind_of?(Class) && constant.superclass == Test::Unit::TestCase
#       puts "adding tests for #{constant.to_s}"
	suite << constant.suite
      end
    end
    suite
  end
end

if __FILE__ == $0
  require 'test/unit/ui/fox/testrunner'
  Dir.glob("TC_*.rb").each do |testcase|
    require "#{testcase}"
  end
  Test::Unit::UI::Fox::TestRunner.run(TS_All)
end


