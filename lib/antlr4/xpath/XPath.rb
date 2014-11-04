#
# Represent a subset of XPath XML path syntax for use in identifying nodes in
# parse trees.
#
# <p>
# Split path into words and separators {@code /} and {@code //} via ANTLR
# itself then walk path elements from left to right. At each separator-word
# pair, find set of nodes. Next stage uses those as work list.</p>
#
# <p>
# The basic interface is
# {@link XPath#findAll ParseTree.findAll}{@code (tree, pathString, parser)}.
# But that is just shorthand for:</p>
#
# <pre>
# {@link XPath} p = new {@link XPath#XPath XPath}(parser, pathString);
# return p.{@link #evaluate evaluate}(tree);
# </pre>
#
# <p>
# See {@code org.antlr.v4.test.TestXPath} for descriptions. In short, this
# allows operators:</p>
#
# <dl>
# <dt>/</dt> <dd>root</dd>
# <dt>//</dt> <dd>anywhere</dd>
# <dt>!</dt> <dd>invert; this must appear directly after root or anywhere
# operator</dd>
# </dl>
#
# <p>
# and path elements:</p>
#
# <dl>
# <dt>ID</dt> <dd>token name</dd>
# <dt>'string'</dt> <dd>any string literal token from the grammar</dd>
# <dt>expr</dt> <dd>rule name</dd>
# <dt>*</dt> <dd>wildcard matching any node</dd>
# </dl>
#
# <p>
# Whitespace is not allowed.</p>
#

class XPathLexer < Lexer
    include JavaSymbols

    @@serializedATN = \
        "\3\uacf5\uee8c\u4f5d\u8b0d\u4a45\u78bd\u1b2f\u3378\2\n\64\b\1\4\2\t\2" + \
        "\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\3\2\3\2\3\2\3" + \
        "\3\3\3\3\4\3\4\3\5\3\5\3\6\3\6\7\6\37\n\6\f\6\16\6\"\13\6\3\6\3\6\3\7" + \
        "\3\7\5\7(\n\7\3\b\3\b\3\t\3\t\7\t.\n\t\f\t\16\t\61\13\t\3\t\3\t\3/\n\3" + \
        "\5\1\5\6\1\7\7\1\t\b\1\13\t\2\r\2\1\17\2\1\21\n\1\3\2\4\7\2\62;aa\u00b9" + \
        "\u00b9\u0302\u0371\u2041\u2042\17\2C\\c|\u00c2\u00d8\u00da\u00f8\u00fa" + \
        "\u0301\u0372\u037f\u0381\u2001\u200e\u200f\u2072\u2191\u2c02\u2ff1\u3003" + \
        "\ud801\uf902\ufdd1\ufdf2\uffff\64\2\3\3\2\2\2\2\5\3\2\2\2\2\7\3\2\2\2" + \
        "\2\t\3\2\2\2\2\13\3\2\2\2\2\21\3\2\2\2\3\23\3\2\2\2\5\26\3\2\2\2\7\30" + \
        "\3\2\2\2\t\32\3\2\2\2\13\34\3\2\2\2\r\'\3\2\2\2\17)\3\2\2\2\21+\3\2\2" + \
        "\2\23\24\7\61\2\2\24\25\7\61\2\2\25\4\3\2\2\2\26\27\7\61\2\2\27\6\3\2" + \
        "\2\2\30\31\7,\2\2\31\b\3\2\2\2\32\33\7#\2\2\33\n\3\2\2\2\34 \5\17\b\2" + \
        "\35\37\5\r\7\2\36\35\3\2\2\2\37\"\3\2\2\2 \36\3\2\2\2 !\3\2\2\2!#\3\2" + \
        "\2\2\" \3\2\2\2#$\b\6\2\2$\f\3\2\2\2%(\5\17\b\2&(\t\2\2\2\'%\3\2\2\2\'" + \
        "&\3\2\2\2(\16\3\2\2\2)*\t\3\2\2*\20\3\2\2\2+/\7)\2\2,.\13\2\2\2-,\3\2" + \
        "\2\2.\61\3\2\2\2/\60\3\2\2\2/-\3\2\2\2\60\62\3\2\2\2\61/\3\2\2\2\62\63" + \
        "\7)\2\2\63\22\3\2\2\2\6\2 \'/"

    TOKEN_REF=1
    RULE_REF=2
    ANYWHERE=3
    ROOT=4
    WILDCARD=5
    BANG=6
    ID=7
    STRING=8


    def initialize(input)
        super(input)
        self.modeNames = [ "DEFAULT_MODE" ]
        self.tokenNames = ["<INVALID>", "TOKEN_REF", "RULE_REF", "'//'", "'/'", "'*'", "'!'", "ID", "STRING" ]
        self.ruleNames = [ "ANYWHERE", "ROOT", "WILDCARD", "BANG", "ID", "NameChar", "NameStartChar", "STRING" ]
        @ATN = ATNDeserializer.new.deserialize(@@serializedATN)
        @interp = LexerATNSimulator.new(@ATN, @decisionToDFA, @sharedContextCache)
        @grammarFileName = "XPathLexer.g4"
        @decisionToDFA = @ATN.decisionToState.map{|s| DFA.new(s)  } 
        @sharedContextCache = PredictionContextCache()
    end


    def action(localctx, ruleIndex, actionIndex)
        if ruleIndex==4 then
            self.ID_action(localctx, actionIndex)
        end
    end

    def ID_action(localctx, actionIndex)
        if actionIndex==0 then
            if self.text[0].is_uppercase?
                self.type = TOKEN_REF
            else
                self.type = RULE_REF
            end
        end
    end
end

class XPath

    WILDCARD = "*" # word not operator/separator
    NOT = "!" # word for invert operator
    def self.WILDCARD
      XPath::WILDCARD
    end
    def self.NOT
      XPath::NOT
    end

    def initialize(parser, path)
        self.parser = parser
        self.path = path
        self.elements = self.split(path)
    end
    def recover(e)
       raise e
    end
    def split(path)
        input = InputStream.new(path)
        lexer = XPathLexer.new(input)
        lexer.recover = recover
        lexer.removeErrorListeners()
        lexer.addErrorListener(ErrorListener.new()) # XPathErrorListener does no more
        tokenStream = CommonTokenStream.new(lexer)
        begin
            tokenStream.fill()
        rescue LexerNoViableAltException => e
            pos = lexer.getColumn()
            msg = "Invalid tokens or characters at index #{pos} in path '#{path}'"
            ex = Exception.new(msg)
            ex.set_backtrace(e.backtrace)
            raise ex
        end

        tokens = tokenStream.getTokens()
        elements = Array.new
        n = tokens.length
        i=0
        while i < n do 
            el = tokens[i]
            next_token = nil
            if [XPathLexer.ROOT, XPathLexer.ANYWHERE].member? el.type then
                    anywhere = el.type == XPathLexer.ANYWHERE
                     i = i + 1
                    next_token = tokens[i]
                    invert = next_token.type==XPathLexer.BANG
                    if invert then
                        i = i + 1
                        next_token = tokens[i]
                    end
                    pathElement = self.getXPathElement(next_token, anywhere)
                    pathElement.invert = invert
                    elements.push(pathElement)
                    i = i + 1
            elsif [XPathLexer.TOKEN_REF, XPathLexer.RULE_REF, XPathLexer.WILDCARD].member? el.type then
                    elements.push( self.getXPathElement(el, false) )
                    i = i + 1
            elsif el.type==Token.EOF then
                    break
            else
                    raise Exception.new("Unknown path element #{el}")
            end
        end
        return elements
    end

    #
    # Convert word like {@code#} or {@code ID} or {@code expr} to a path
    # element. {@code anywhere} is {@code true} if {@code //} precedes the
    # word.
    #
    def getXPathElement(wordToken, anywhere)
        if wordToken.type==Token.EOF then
            raise Exception.new("Missing path element at end of path")
        end
        word = wordToken.text
        ttype = self.parser.getTokenType(word)
        ruleIndex = self.parser.getRuleIndex(word)

        if wordToken.type==XPathLexer.WILDCARD then
            if anywhere then
              return XPathWildcardAnywhereElement.new() 
            else  
              return XPathWildcardElement.new()
            end
        elsif [XPathLexer.TOKEN_REF, XPathLexer.STRING].member?  wordToken.type 
            if ttype==Token.INVALID_TYPE then
                raise Exception.new("#{word} at index #{wordToken.startIndex} isn't a valid token name")
            end
            if anywhere then 
              return XPathTokenAnywhereElement.new(word, ttype)   
            else 
                return XPathTokenElement.new(word, ttype)
            end
        else
            if ruleIndex==-1 then
                raise Exception( "#{word} at index #{wordToken.getStartIndex()} isn't a valid rule name")
            end
            if anywhere 
              return XPathRuleAnywhereElement.new(word, ruleIndex)  
            else 
              return XPathRuleElement.new(word, ruleIndex)
            end
        end
    end

    def findAll(tree, xpath, parser)
        p = XPath.new(parser, xpath)
        return p.evaluate(tree)
    end
    #
    # Return a list of all nodes starting at {@code t} as root that satisfy the
    # path. The root {@code /} is relative to the node passed to
    # {@link #evaluate}.
    #
    def evaluate(t)
        dummyRoot = ParserRuleContext.new()
        dummyRoot.children = [t] # don't set t's parent.
        work = [dummyRoot]
        for i in (0 .. (self.elements.length-1)) do
            next_token = Set.new()
            for node in work do
                if node.children.length > 0 then
                    # only try to match next element if it has children
                    # e.g., //func/*/stat might have a token node for which
                    # we can't go looking for stat nodes.
                    matching = self.elements[i].evaluate(node)
                    next_token.union(matching)
                end
            end
            i = i + 1
            work = next_token
        end
        return work
    end
end
class XPathElement

    attr_accessor :nodeNode, :invert
    def initialize(nodename)
        self.nodeName = nodename
        self.invert = false
    end

    def to_s 
        c = "!" if self.invert
        return "#{self.class.to_s}[#{c}#{self.nodeName}]"
    end
end
#
# Either {@code ID} at start of path or {@code ...//ID} in middle of path.
#
class XPathRuleAnywhereElement < XPathElement

    attr_accessor :ruleIndex
    def initialize(rule_name, rule_index)
        super(rule_name)
        self.ruleIndex = rule_index
    end

    def evaluate(t)
        return Trees.findAllRuleNodes(t, self.ruleIndex)
    end
end

class XPathRuleElement <  XPathRuleAnywhereElement 

    def initialize(rulename, ruleindex)
        super(rulename, ruleindex)
    end
    def evaluate(t)
        # return all children of t that match nodeName
        nodes = []
        for c in Trees.getChildren(t) do
            if c.kind_of? ParserRuleContext  then
                if (c.ruleIndex == self.ruleIndex ) == (not self.invert) then
                    nodes.push(c)
                end
            end
        end
        return nodes
    end
end
class XPathTokenAnywhereElement < XPathElement

    attr_accessor :tokenType
    def initialize(rulename, tokentype)
        super(rulename)
        self.tokenType = tokentype
    end

    def evaluate(t)
        return Trees.findAllTokenNodes(t, self.tokenType)
    end
end

class XPathTokenElement < XPathTokenAnywhereElement

    def initialize(rulename, tokentype)
        super(rulename, tokentype)
    end

    def evaluate(t)
        # return all children of t that match nodeName
        nodes = []
        for c in Trees.getChildren(t) do
            if c.kind_of? TerminalNode then
                if (c.symbol.type == self.tokenType ) == (not self.invert) then
                    nodes.push(c)
                end
            end
        end
        return nodes
    end
end

class XPathWildcardAnywhereElement < XPathElement

    def initialize()
        super(XPath::WILDCARD)
    end

    def evaluate(t)
        if self.invert then
            return [] # !* is weird but valid (empty)
        else
            return Trees.descendants(t)
        end
    end
end

class XPathWildcardElement < XPathElement

    def initialize()
        super(XPath::WILDCARD)
    end


    def evaluate(t)
        if self.invert then
            return [] # !* is weird but valid (empty)
        else
            return Trees.getChildren(t)
        end
    end
end
