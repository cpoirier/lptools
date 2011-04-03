#!/usr/bin/ruby
#
# Used to require the builtin functions
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

require 'tapestry-packaged/Error.rb'
require 'tapestry-packaged/build/interpreter/Tokenizer.rb'
require 'tapestry-packaged/build/interpreter/Interpreter.rb'
require 'tapestry-packaged/build/interpreter/Function.rb'


require 'tapestry-packaged/build/interpreter/functions/core/InterpreterTest.rb'

require 'tapestry-packaged/build/interpreter/functions/core/Mainline.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Loops.rb'
require 'tapestry-packaged/build/interpreter/functions/core/If.rb'

require 'tapestry-packaged/build/interpreter/functions/core/Variables.rb'
require 'tapestry-packaged/build/interpreter/functions/core/VariableExpansion.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Quoting.rb'
require 'tapestry-packaged/build/interpreter/functions/core/UserDefined.rb'

require 'tapestry-packaged/build/interpreter/functions/core/Constants.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Booleans.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Tests.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Conversions.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Vectors.rb'

require 'tapestry-packaged/build/interpreter/functions/core/IO.rb'
require 'tapestry-packaged/build/interpreter/functions/core/PatternMatching.rb'
require 'tapestry-packaged/build/interpreter/functions/core/Wildcards.rb'


require 'tapestry-packaged/build/interpreter/functions/operations/Productions.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Sources.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Aliases.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Macros.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Analyzers.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Actions.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Zones.rb'
require 'tapestry-packaged/build/interpreter/functions/operations/Nodes.rb'

