# The basic notion of a tree has a parent, a payload, and a list of children.
#  It is the most abstract interface for all the trees used by ANTLR.
#

class Tree
end

class SyntaxTree < Tree
end

class ParseTree < SyntaxTree
end

class RuleNode < ParseTree
end

class TerminalNode < ParseTree
end

class ErrorNode < TerminalNode
end


# This interface defines the basic notion of a parse tree visitor. Generated
# visitors implement this interface and the {@code XVisitor} interface for
# grammar {@code X}.
class ParseTreeVisitor
	 # Visit a parse tree, and return a user-defined result of the operation.
	 #
	 # @param tree The {@link ParseTree} to visit.
	 # @return The result of visiting the parse tree.
	def visit(tree) # tree:ParseTree 
  end
	# Visit the children of a node, and return a user-defined result of the
	# operation.
	# @param node The {@link RuleNode} whose children should be visited.
	# @return The result of visiting the children of the node.
	def visitChildren(node) # node:RuleNode 
  end

	# Visit a terminal node, and return a user-defined result of the operation.
	#
	# @param node The {@link TerminalNode} to visit.
	# @return The result of visiting the node.
	def visitTerminal(node) # node:TerminalNode 
  end
  #Visit an error node, and return a user-defined result of the operation.
  #
	# @param node The {@link ErrorNode} to visit.
	# @return The result of visiting the node.
	def visitErrorNode(node) # node:ErrorNode 
  end
end

class ParseTreeListener
    def visitTerminal(node)
    end

    def visitErrorNode(node)
    end

    def enterEveryRule(ctx)
    end

    def exitEveryRule(ctx)
    end
end

module NodeImpl

  def self.included(klass)
    klass.send(:include, NodeImpl::Methods)
    # klass.send(:extend, NodeImpl::Methods)
    # klass.send(:extend, NodeImpl::ClassMethods)
  end
  module Methods
    def initialize(symbol)
        @parentCtx = nil
        @symbol = symbol
    end
    def symbol
      @symbol
    end
    def symbol=(value)
      @symbol = value
    end
    def parentCtx
      @parentCtx
    end
    def parentCtx=(value)
      @parentCtx = value
    end

#    def []=(key, value)
#        super(key, value)
#    end

    def getChild(i)
        nil
    end

    def getSymbol()
        self.symbol
    end

    def getParent()
        self.parentCtx
    end

    def getPayload()
        return self.symbol
    end

    def getSourceInterval()
        return Antlr4::INVALID_INTERVAL if self.symbol.nil?
        tokenIndex = self.symbol.tokenIndex
        return [tokenIndex, tokenIndex]
    end

    def getChildCount()
        return 0
    end

    def accept(visitor)
        return visitor.visitTerminal(self)
    end

    def getText()
        return self.symbol.text
    end

    def to_s
        if self.symbol.type == Token::EOF then
            "<EOF>"
        else
            self.symbol.text
        end
    end
  end
end

class TerminalNodeImpl < TerminalNode
    include NodeImpl

end
# Represents a token that was consumed during resynchronization
#  rather than during a valid match operation. For example,
#  we will create this kind of a node during single token insertion
#  and deletion as well as during "consume until error recovery set"
#  upon no viable alternative exceptions.

class ErrorNodeImpl < ErrorNode
    include NodeImpl 

    def accept(visitor)
        return visitor.visitErrorNode(self)
    end
end


class ParseTreeWalker
    # ParseTreeWalker.DEFAULT = ParseTreeWalker()
    @@default  = nil
    def self.DEFAULT
        if @@default.nil? 
          @@default = new
        end
        @@default
    end
    def walk(listener, t)
        if t.kind_of?  ErrorNode then
            listener.visitErrorNode(t)
            return
        elsif t.kind_of? TerminalNode then
            listener.visitTerminal(t)
            return
        end
        self.enterRule(listener, t)
        for child in t.getChildren() 
            self.walk(listener, child)
        end
        self.exitRule(listener, t)
    end
    #
    # The discovery of a rule node, involves sending two events: the generic
    # {@link ParseTreeListener#enterEveryRule} and a
    # {@link RuleContext}-specific event. First we trigger the generic and then
    # the rule specific. We to them in reverse order upon finishing the node.
    #
    def enterRule(listener, r)
        ctx = r.getRuleContext()
        listener.enterEveryRule(ctx)
        ctx.enterRule(listener)
    end

    def exitRule(listener, r)
        ctx = r.getRuleContext()
        ctx.exitRule(listener)
        listener.exitEveryRule(ctx)
    end
end
