#
#from antlr4 import Lexer, CommonTokenStream, ParserRuleContext
#from antlr4.InputStream import InputStream
#from antlr4.ListTokenSource import ListTokenSource
#from antlr4.Token import Token
#from antlr4.error.ErrorStrategy import BailErrorStrategy
#from antlr4.error.Errors import RecognitionException, ParseCancellationException
#from antlr4.tree.Chunk import TagChunk, TextChunk
#from antlr4.tree.RuleTagToken import RuleTagToken
##from antlr4.tree.TokenTagToken import TokenTagToken
#from antlr4.tree.Tree import ParseTree, TerminalNode, RuleNode
        #from antlr4.tree.ParseTreeMatch import ParseTreeMatch
#        from antlr4.tree.ParseTreePattern import ParseTreePattern

class CannotInvokeStartRule < Exception
end

class StartRuleDoesNotConsumeFullPattern < Exception
end

class ParseTreePatternMatcher
    # Constructs a {@link ParseTreePatternMatcher} or from a {@link Lexer} and
    # {@link Parser} object. The lexer input stream is altered for tokenizing
    # the tree patterns. The parser is used as a convenient mechanism to get
    # the grammar name, plus token, rule names.
    attr_accessor :lexer, :parser, :start, :stop, :escape
    def initialize(lexer, parser)
        self.lexer = lexer
        self.parser = parser
        self.start = "<"
        self.stop = ">"
        self.escape = "\\"  # e.g., \< and \> must escape BOTH!
    end

    # Set the delimiters used for marking rule and token tags within concrete
    # syntax used by the tree pattern parser.
    #
    # @param start The start delimiter.
    # @param stop The stop delimiter.
    # @param escapeLeft The escape sequence to use for escaping a start or stop delimiter.
    #
    # @exception IllegalArgumentException if {@code start} is {@code null} or empty.
    # @exception IllegalArgumentException if {@code stop} is {@code null} or empty.
    #
    def setDelimiters(start, stop, escapeLeft)
        raise Exception.new("start cannot be null or empty") if start.nil? or start.empty? 
        raise Exception.new("stop cannot be null or empty") if stop.nil? or stop.empty?
        self.start = start
        self.stop = stop
        self.escape = escapeLeft
    end

    # Does {@code pattern} matched as rule {@code patternRuleIndex} match {@code tree}?#
    def matchesRuleIndex(tree, pattern, patternRuleIndex)
        p = self.compileTreePattern(pattern, patternRuleIndex)
        return self.matches(tree, p)
    end

    # Does {@code pattern} matched as rule patternRuleIndex match tree? Pass in a
    #  compiled pattern instead of a string representation of a tree pattern.
    #
    def matchesPattern(tree, pattern)
        mismatchedNode = self.matchImpl(tree, pattern.patternTree, Hash.new)
        return mismatchedNode.nil? 
    end

    #
    # Compare {@code pattern} matched as rule {@code patternRuleIndex} against
    # {@code tree} and return a {@link ParseTreeMatch} object that contains the
    # matched elements, or the node at which the match failed.
    #
    def matchRuleIndex(tree, pattern, patternRuleIndex)
        p = self.compileTreePattern(pattern, patternRuleIndex)
        return self.matchPattern(tree, p)
    end

    #
    # Compare {@code pattern} matched against {@code tree} and return a
    # {@link ParseTreeMatch} object that contains the matched elements, or the
    # node at which the match failed. Pass in a compiled pattern instead of a
    # string representation of a tree pattern.
    #
    def matchPattern(tree, pattern)
        labels = Hash.new
        mismatchedNode = self.matchImpl(tree, pattern.patternTree, labels)
        return ParseTreeMatch.new(tree, pattern, labels, mismatchedNode)
    end

    #
    # For repeated use of a tree pattern, compile it to a
    # {@link ParseTreePattern} using this method.
    #
    def compileTreePattern(pattern, patternRuleIndex)
        tokenList = self.tokenize(pattern)
        tokenSrc = ListTokenSource.new(tokenList)
        tokens = CommonTokenStream.new(tokenSrc)
#        from antlr4.ParserInterpreter import ParserInterpreter

        p = self.parser
        parserInterp = ParserInterpreter.new(p.grammarFileName, p.tokenNames, p.ruleNames, 
                                              p.getATNWithBypassAlts(),tokens)
        tree = nil
        begin
            parserInterp.setErrorHandler(BailErrorStrategy())
            tree = parserInterp.parse(patternRuleIndex)
        rescue ParseCancellationException => e
            raise e.cause
        rescue RecognitionException => e
            raise e
        rescue Exception => e
            raise CannotInvokeStartRule.new(e)
        end

        # Make sure tree pattern compilation checks for a complete parse
        if tokens.LA(1)!=Token.EOF then
            raise StartRuleDoesNotConsumeFullPattern.new()
        end

        return ParseTreePattern.new(self, pattern, patternRuleIndex, tree)
    end
    #
    # Recursively walk {@code tree} against {@code patternTree}, filling
    # {@code match.}{@link ParseTreeMatch#labels labels}.
    #
    # @return the first node encountered in {@code tree} which does not match
    # a corresponding node in {@code patternTree}, or {@code null} if the match
    # was successful. The specific node returned depends on the matching
    # algorithm used by the implementation, and may be overridden.
    #
    def matchImpl(tree, patternTree, labels)
        raise Exception.new("tree cannot be null") if tree.nil?
        raise Exception.new("patternTree cannot be null") if patternTree.nil?

        # x and <ID>, x and y, or x and x; or could be mismatched types
        if tree.kind_of? TerminalNode and patternTree.kind_of? TerminalNode then
            mismatchedNode = nil
            # both are tokens and they have same type
            if tree.symbol.type == patternTree.symbol.type then
                if patternTree.symbol.kind_of? TokenTagToken then # x and <ID>
                    tokenTagToken = patternTree.symbol
                    # track label->list-of-nodes for both token name and label (if any)
                    self.map(labels, tokenTagToken.tokenName, tree)
                    if not tokenTagToken.label.nil? 
                        self.map(labels, tokenTagToken.label, tree)
                    end
                elsif tree.getText()==patternTree.getText() then
                    # x and x
                    nil
                else
                    # x and y
                    mismatchedNode = tree if mismatchedNode.nil?
                end
            else
                mismatchedNode = tree if mismatchedNode.nil? 
            end

            return mismatchedNode
        end

        if tree.kind_of? ParserRuleContext and patternTree.kind_of?  ParserRuleContext then
            mismatchedNode = nil
            # (expr ...) and <expr>
            ruleTagToken = self.getRuleTagToken(patternTree)
            if not ruleTagToken.nil? then
                m = nil
                if tree.ruleContext.ruleIndex == patternTree.ruleContext.ruleIndex then
                    # track label->list-of-nodes for both rule name and label (if any)
                    self.map(labels, ruleTagToken.ruleName, tree)
                    if not ruleTagToken.label.nil? then
                        self.map(labels, ruleTagToken.label, tree)
                    end
                else
                    mismatchedNode = tree if mismatchedNode.nil?
                end
                return mismatchedNode
            end

            # (expr ...) and (expr ...)
            if tree.getChildCount()!=patternTree.getChildCount() then
                mismatchedNode = tree if mismatchedNode.nil?
                return mismatchedNode
            end

            n = tree.getChildCount()
            for i in 0..n-1 do
                childMatch = self.matchImpl(tree.getChild(i), patternTree.getChild(i), labels)
                return childMatch if not childMatch.nil? 
            end
            return mismatchedNode
        end
        # if nodes aren't both tokens or both rule nodes, can't match
        return tree
    end
    def map(labels, label, tree)
        v = labels.get(label, nil)
        if v.nil? 
            v = Array.new
        end
        v.push(tree)
        labels[label] = v
    end
    # Is {@code t} {@code (expr <expr>)} subtree?#
    def getRuleTagToken(tree)
        if tree.kind_of? RuleNode then
            if tree.getChildCount()==1 and tree.getChild(0).kind_of?  TerminalNode then
                c = tree.getChild(0)
                return c.symbol if c.symbol.kind_of?  RuleTagToken
            end
        end
        return nil
    end
    def tokenize(pattern)
        # split pattern into chunks: sea (raw input) and islands (<ID>, <expr>)
        chunks = self.split(pattern)

        # create token stream from text and tags
        tokens = Array.new
        for chunk in chunks do
            if chunk.kind_of? TagChunk then
                # add special rule token or conjure up new token from name
                if chunk.tag[0].isupper() then
                    ttype = self.parser.getTokenType(chunk.tag)
                    if ttype==Token.INVALID_TYPE then
                        raise Exception.new("Unknown token #{chunk.tag} in pattern: #{pattern}")
                    end
                    tokens.push(TokenTagToken(chunk.tag, ttype, chunk.label))
                elsif chunk.tag[0].islower() then
                    ruleIndex = self.parser.getRuleIndex(chunk.tag)
                    if ruleIndex==-1 then
                        raise Exception.new("Unknown rule #{chunk.tag} in pattern: #{pattern}")
                    end
                    ruleImaginaryTokenType = self.parser.getATNWithBypassAlts().ruleToTokenType[ruleIndex]
                    tokens.push(RuleTagToken(chunk.tag, ruleImaginaryTokenType, chunk.label))
                else
                    raise Exception.new("Invalid tag #{chunk.tag} in pattern: #{pattern}")
                end
            else
                self.lexer.setInputStream(InputStream.new(chunk.text))
                t = self.lexer.nextToken()
                while t.type!=Token.EOF do 
                    tokens.push(t)
                    t = self.lexer.nextToken()
                end
            end
        end
        return tokens
    end 
    # Split {@code <ID> = <e:expr> ;} into 4 chunks for tokenizing by {@link #tokenize}.#
    def split(pattern)
        p = 0
        n = pattern.length
        chunks = list()
        # find all start and stop indexes first, then collect
        starts = Array.new
        stops = Array.new
        while p < n do
            if p == pattern.find(self.escape + self.start, p) then
                p = p + self.escape.length + self.start.length
            elsif p == pattern.find(self.escape + self.stop, p) then
                p = p + self.escape.length + self.stop.length
            elsif p == pattern.find(self.start, p) then
                starts.push(p)
                p = p + self.start.length
            elsif p == pattern.find(self.stop, p) then
                stops.push(p)
                p = p + self.stop.length
            else
                p = p + 1
            end
        end
        nt = starts.length

        if nt > stops.length
            raise Exception.new("unterminated tag in pattern: #{pattern}")
        end
        if nt < stops.length
            raise Exception.new("missing start tag in pattern: #{pattern}")
        end

        for i in 0..(nt-1) do
            if starts[i] >= stops[i] then
                raise Exception.new("tag delimiters out of order in pattern: " + pattern)
            end
        end

        # collect into chunks now
        chunks.push(TextChunk.new(pattern)) if nt==0

        if nt>0 and starts[0]>0 then # copy text up to first tag into chunks
            text = pattern[0,starts[0]-1]
            chunks.add(TextChunk.new(text))
        end

        for i in 0..(nt-1) do
            # copy inside of <tag>
            tag = pattern[starts[i] + len(self.start) , stops[i]-1]
            ruleOrToken = tag
            label = nil
            colon = tag.find(':')
            if colon >= 0 then
                label = tag[0,colon-1]
                ruleOrToken = tag[colon+1 , tag.length-1]
            end
            chunks.push(TagChunk.new(label, ruleOrToken))
            if i+1 < (starts.length) then
                # copy from end of <tag> to start of next
                text = pattern[stops[i] + self.stop.length() , starts[i +1]-1]
                chunks.push(TextChunk.new(text))
            end
        end

        if nt > 0 then
            afterLastTag = stops[nt - 1] + self.stop.length
            if afterLastTag < n then # copy text from end of last tag to end
                text = pattern[afterLastTag , n -1]
                chunks.push(TextChunk.new(text))
            end
        end

        # strip out the escape sequences from text chunks but not tags
        return chunks.map do |c| 
            if c.kind_of? TextChunk then
                unescaped = c.text.replace(self.escape, "")
                if unescaped.length < c.text.length then
                   TextChunk.new(unescaped)
                else
                   c
                end
            else 
                c
            end
        end
    end
end
