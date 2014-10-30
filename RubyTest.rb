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
  input = File.open(args[0])
  inputstream = InputStream.new(input.read)
  lexer = PjmInvoiceLexer.new(inputstream)
  stream = CommonTokenStream.new(lexer)
  stream.fill()
#  for i in stream.tokens do
#      puts "#{i}"
#  end
  puts  "Finish First Lexing"
  input.seek(0)
  inputstream = InputStream.new(input.read)
  lexer = PjmInvoiceLexer.new(inputstream)
#  puts lexer.modeNames, lexer.tokenNames, lexer.ruleNames

  stream = CommonTokenStream.new(lexer)
  # print(lexer._interp.decisionToDFA[Lexer.DEFAULT_MODE].toLexerString(), end='')
  stream.fill
  puts stream.tokens.map{|token| token.to_s }.inspect
	parser = PjmInvoiceParser.new(stream)
  parser.setTrace(true)
  parser.buildParseTrees = true 
  tree = parser.main() 
  ParseTreeWalker.DEFAULT.walk(TreeShapeListener.new(), tree)
end


main(ARGV)
