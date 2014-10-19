# A set of utility routines useful for all kinds of ANTLR trees.#
#from io import StringIO
#from antlr4.Token import Token
#from antlr4.Utils import escapeWhitespace
#from antlr4.tree.Tree import RuleNode, ErrorNode, TerminalNode, Tree, ParseTree

class Trees

     # Print out a whole tree in LISP form. {@link #getNodeText} is used on the
    #  node payloads to get the text for the nodes.  Detect
    #  parse trees and extract data appropriately.
    def self.toStringTree(t, ruleNames=nil, recog=nil)
        if not recog.nil? then 
            ruleNames = recog.ruleNames
        end
        s = getNodeText(t, ruleNames).escapeWhitespace(false)
        if t.getChildCount()==0 then
            return s
        end
        StringIO.new() do |buf|
            buf.write("(")
            buf.write(s)
            buf.write(' ')
            for i in 0..t.getChildCount()-1 do
                if i > 0 then
                    buf.write(' ')
                end
                buf.write(toStringTree(t.getChild(i), ruleNames))
            end
            buf.write(")")
            return buf.string()
        end
    end
    def self.getNodeText(t, ruleNames=nil, recog=nil) 
        if not recog.nil? then 
            ruleNames = recog.ruleNames
        end
        if not ruleNames.nil? then 
            if t.kind_of? RuleNode then
                return ruleNames[t.getRuleContext().getRuleIndex()]
            elsif t.kind_of? ErrorNode then
                return t.to_s
            elsif t.kind_of? TerminalNode then
                if not t.symbol.nil? then 
                    return t.symbol.text
                end
            end
        end
        # no recog for rule names
        payload = t.getPayload()
        if payload.kind_of? Token then
            return payload.text
        end
        return t.getPayload().to_s
    end

    # Return ordered list of all children of this node
    def self.getChildren(t)
        return (0 .. t.getChildCount()-1).map{|i| t.getChild(i) }
    end

    # Return a list of all ancestors of this node.  The first node of
    #  list is the root and the last is the parent of this node.
    #
    def self.getAncestors(t)
        ancestors = []
        t = t.getParent()
        while not t.nil? do
            ancestors.unshift(t) # insert at start
            t = t.getParent()
        end
        return ancestors
    end

    def self.findAllTokenNodes(t, ttype)
        return findAllNodes(t, ttype, true)
    end

    def self.findAllRuleNodes(t, ruleIndex)
        return findAllNodes(t, ruleIndex, false)
    end

    def self.findAllNodes(cls, t, index, findTokens)
        nodes = Array.new
        _findAllNodes(t, index, findTokens, nodes)
        return nodes
    end

    def self._findAllNodes(t, index, findTokens, nodes)
        #from antlr4.ParserRuleContext import ParserRuleContext
        # check this node (the root) first
        if findTokens and t.kind_of? TerminalNode then
            nodes.push(t) if t.symbol.type==index
        elsif not findTokens and t.kind_of? ParserRuleContext then
            nodes.push(t) if t.ruleIndex == index
        end
        # check children
        for i in 0 .. t.getChildCount()-1
            self._findAllNodes(t.getChild(i), index, findTokens, nodes)
        end
    end

    def self.descendants(t)
        nodes = Array.new
        nodes.push(t)
        for i in 0..t.getChildCount()-1 
            nodes.concat(self.descendants(t.getChild(i)))
        end
        return nodes
    end
end
