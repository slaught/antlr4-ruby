# The basic notion of a tree has a parent, a payload, and a list of children.
#  It is the most abstract interface for all the trees used by ANTLR.
#/
#from antlr4.Token import Token

INVALID_INTERVAL = [-1, -2]

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

class ParseTreeVisitor
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
        self.parentCtx = nil
        self.symbol = symbol
    end

#    attr_accessor :symbol, :parentCtx

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
        return INVALID_INTERVAL if self.symbol.nil? 
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
        if self.symbol.type == Token.EOF then
            "<EOF>"
        else
            self.symbol.text
        end
    end
  end
end

class TerminalNodeImpl < TerminalNode

    include NodeImpl

    attr_accessor :symbol, :parentCtx
#    def initialize(symbol)
#        self.parentCtx = nil
#        self.symbol = symbol
#    end
#
#    def __setattr__(self, key, value):
#        super().__setattr__(key, value)
#    end
#
#    def getChild(i)
#        nil
#    end
#
#    def getSymbol()
#        self.symbol
#    end
#
#    def getParent()
#        self.parentCtx
#    end
#
#    def getPayload()
#        return self.symbol
#    end
#
#    def getSourceInterval()
#        return INVALID_INTERVAL if self.symbol.nil? 
#        tokenIndex = self.symbol.tokenIndex
#        return (tokenIndex, tokenIndex)
#    end
#
#    def getChildCount()
#        return 0
#    end

#    def accept(visitor)
#        return visitor.visitTerminal(self)
#    end
#
#    def getText()
#        return self.symbol.text
#    end
#
#    def to_s
#        if self.symbol.type == Token.EOF then
#            "<EOF>"
#        else
#            self.symbol.text
#        end
#    end
end
# Represents a token that was consumed during resynchronization
#  rather than during a valid match operation. For example,
#  we will create this kind of a node during single token insertion
#  and deletion as well as during "consume until error recovery set"
#  upon no viable alternative exceptions.

class ErrorNodeImpl < ErrorNode
    include NodeImpl 
    attr_accessor :symbol, :parentCtx

    def initialize(token)
        super(token)
    end

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
