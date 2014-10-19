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
    sub(" ", c).sub("\t","\\t").sub("\n","\\n").sub("\r","\\r")
  end
end

class Hash
  def get(x,y)
    return fetch(x) if self.has_key? x
    return y
  end
end
