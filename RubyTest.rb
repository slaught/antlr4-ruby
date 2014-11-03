require 'PjmInvoiceListener'
require 'PjmInvoiceLexer'
require 'PjmInvoiceParser'
require 'PjmInvoiceLexer'
require 'PjmInvoiceParser'
require 'antlr4'

class TreeShapeListener < ParseTreeListener
  def visitTerminal(node)
  end
  def visitErrorNode(node)
  end
  def exitEveryRule(ctx)
  end
  def enterEveryRule(ctx)
			for child in ctx.getChildren() 
					parent = child.parentCtx
				  if not parent.kind_of? RuleNode or parent.getRuleContext() != ctx then
						 raise IllegalStateException.new("Invalid parse tree shape detected.")
          end
      end
  end
end



def main(args) 

  if args.length == 1 then
      primary_test(args[0])
  else
    if args[0] == 'test_token_stream' then
        test_token_stream(args[1])
    elsif args[0] == 'test1' then
        test1(args[1])
    else
      puts "Skipping"
    end
  end
end
def primary_test(fn)
  input = File.open(fn,'rb')
  inputstream = InputStream.new(input.read)
  lexer = PjmInvoiceLexer.new(inputstream)
  stream = CommonTokenStream.new(lexer)
	parser = PjmInvoiceParser.new(stream)

  atn = parser.interp.atn
  atn.states.each {|s| 
      puts "(#{s}) : #{s.class}"
  }
  atn.states.each {|s| 
      nexttokens = atn.nextTokens(s).toString(parser.tokenNames)
#      n = parser.tokenNames[s]
#      puts "(#{s}) : #{nexttokens}"
  }
  exit -1


#  parser.setTrace(true)
  parser.buildParseTrees = true 
  tree = parser.main() 
  ParseTreeWalker.DEFAULT.walk(TreeShapeListener.new(), tree)
end
def create_token_stream(fn)
  input = File.open(fn) 
  inputstream = InputStream.new(input.read)
  lexer = PjmInvoiceLexer.new(inputstream)
  stream = CommonTokenStream.new(lexer)
end
def test_token_stream(fn)
  stream = create_token_stream(fn) 
  stream.fill()
  for i in stream.tokens do
      puts "#{i}"
  end
end
def test1(fn)
  input = File.open(fn)
  inputstream = InputStream.new(input.read)
  lexer = PjmInvoiceLexer.new(inputstream)
  stream = CommonTokenStream.new(lexer)
#  stream.fill()
#  for i in stream.tokens do
#      puts "#{i}"
#  end
#  input.seek(0)
#  inputstream = InputStream.new(input.read)
#  lexer = PjmInvoiceLexer.new(inputstream)
#  puts lexer.modeNames, lexer.tokenNames, lexer.ruleNames

#  stream = CommonTokenStream.new(lexer)
  # print(lexer._interp.decisionToDFA[Lexer.DEFAULT_MODE].toLexerString(), end='')
#  stream.fill
#  puts stream.tokens.map{|token| token.to_s }.inspect
#  puts "Testing Transitions"
#  puts Transition.serializationTypes.inspect

	parser = PjmInvoiceParser.new(stream)
 # parser.setTrace(true)
  parser.buildParseTrees = true 
  tree = parser.main() 

  ParseTreeWalker.DEFAULT.walk(TreeShapeListener.new(), tree)
end


main(ARGV)
