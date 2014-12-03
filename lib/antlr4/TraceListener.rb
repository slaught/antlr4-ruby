class TraceListener < ParseTreeListener
    
    attr :parser
    def initialize(parser=nil)
        super()
        if parser then
          @parser = parser 
        end
    end
    def enterEveryRule(ctx)
        puts "enter   #{parser.ruleNames[ctx.ruleIndex]}, LT(1)=#{parser.input.LT(1).text.to_s}"
    end

    def visitTerminal(node)
        puts "consume #{node.symbol} rule #{parser.ruleNames[parser.ctx.ruleIndex]}"
    end
    def visitErrorNode(node)
    end

    def exitEveryRule(ctx)
        puts "exit    #{parser.ruleNames[ctx.ruleIndex]}, LT(1)=#{parser.input.LT(1).text}"
    end
end
