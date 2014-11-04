require 'Token' 
require 'FileStream'
require 'TokenStream' 
require 'BufferedTokenStream'
require 'CommonTokenStream'
require 'Lexer'
require 'Parser'
require 'dfa/DFA'
require 'atn/ATN'
require 'atn/ATNDeserializer'
require 'atn/LexerATNSimulator'
require 'atn/ParserATNSimulator' 
require 'atn/PredictionMode'
require 'PredictionContext'
require 'ParserRuleContext'
require 'tree/Tree' # import ParseTreeListener, ParseTreeVisitor, ParseTreeWalker, TerminalNode, ErrorNode, RuleNode
require 'error'    #  Errors import RecognitionException, IllegalStateException, NoViableAltException
require 'error/ErrorStrategy' # import BailErrorStrategy
require 'error/DiagnosticErrorListener' # import DiagnosticErrorListener

require 'java_symbols'

module Antlr4
  INVALID_INTERVAL = Range.new(-1, -2)
end

class Range
  def stop
    last
  end
  def start
    first
  end
end


class String
  def is_uppercase?
    self == self.upcase
  end
  def escapeWhitespace(escapeSpaces=false)
    if escapeSpaces then
      c = "\xB7"
    else
      c = " "
    end
    gsub(" ", c).gsub("\t","\\t").gsub("\n","\\n").gsub("\r","\\r")
  end
end

class Hash
  def get(x,y)
    return fetch(x) if self.has_key? x
    return y
  end
end


class Set
  def remove(a)
    delete(a)
  end
end

class Object

  def type_check(o, t)
    unless o.kind_of? t 
      raise Exception.new("Fail Type Check! #{o.class} is not kind of #{t}" )
    end
  end
end
