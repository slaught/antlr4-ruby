
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


# self is all the parsing support code essentially; most of it is error recovery stuff.#
class Parser < Recognizer

    include JavaSymbols
    # self field maps from the serialized ATN string to the deserialized {@link ATN} with
    # bypass alternatives.
    #
    # @see ATNDeserializationOptions#isGenerateRuleBypassTransitions()
    #
    @@bypassAltsAtnCache = Hash.new

    attr_accessor :input,:errHandler,:precedenceStack ,:ctx, :buildParseTrees
    attr_accessor :tracer, :parseListeners, :syntaxErrors 
    attr_accessor :tokenNames
    def initialize(input)
        super()
        # The input stream.
        self.input = nil
        # The error handling strategy for the parser. The default value is a new
        # instance of {@link DefaultErrorStrategy}.
        self.errHandler = DefaultErrorStrategy.new()
        self.precedenceStack = Array.new
        self.precedenceStack.push(0)
        # The {@link ParserRuleContext} object for the currently executing rule.
        # self is always non-null during the parsing process.
        self.ctx = nil
        # Specifies whether or not the parser should construct a parse tree during
        # the parsing process. The default value is {@code true}.
        self.buildParseTrees = true
        # When {@link #setTrace}{@code (true)} is called, a reference to the
        # {@link TraceListener} is stored here so it can be easily removed in a
        # later call to {@link #setTrace}{@code (false)}. The listener itself is
        # implemented as a parser listener so self field is not directly used by
        # other parser methods.
        @tracer = nil
        # The list of {@link ParseTreeListener} listeners registered to receive
        # events during the parse.
        @parseListeners = []
        # The number of syntax errors reported during parsing. self value is
        # incremented each time {@link #notifyErrorListeners} is called.
        @syntaxErrors = 0
        self.setInputStream(input)
    end

    # reset the parser's state#
    def reset()
        self.input.seek(0) unless @input.nil?
        @errHandler.reset(self)
        @ctx = nil
        @syntaxErrors = 0
        self.setTrace(false)
        @precedenceStack = Array.new
        @precedenceStack.push(0)
        @interp.reset() unless @interp.nil?
    end

    # Match current input symbol against {@code ttype}. If the symbol type
    # matches, {@link ANTLRErrorStrategy#reportMatch} and {@link #consume} are
    # called to complete the match process.
    #
    # <p>If the symbol type does not match,
    # {@link ANTLRErrorStrategy#recoverInline} is called on the current error
    # strategy to attempt recovery. If {@link #getBuildParseTree} is
    # {@code true} and the token index of the symbol returned by
    # {@link ANTLRErrorStrategy#recoverInline} is -1, the symbol is added to
    # the parse tree by calling {@link ParserRuleContext#addErrorNode}.</p>
    #
    # @param ttype the token type to match
    # @return the matched symbol
    # @throws RecognitionException if the current input symbol did not match
    # {@code ttype} and the error strategy could not recover from the
    # mismatched symbol

    def match(ttype)
        t = self.getCurrentToken()
        if t.type==ttype
            self.errHandler.reportMatch(self)
            self.consume()
        else
            t = self.errHandler.recoverInline(self)
            if self.buildParseTrees and t.tokenIndex==-1
                # we must have conjured up a new token during single token insertion
                # if it's not the current symbol
                self.ctx.addErrorNode(t)
            end
        end
        return t
    end

    # Match current input symbol as a wildcard. If the symbol type matches
    # (i.e. has a value greater than 0), {@link ANTLRErrorStrategy#reportMatch}
    # and {@link #consume} are called to complete the match process.
    #
    # <p>If the symbol type does not match,
    # {@link ANTLRErrorStrategy#recoverInline} is called on the current error
    # strategy to attempt recovery. If {@link #getBuildParseTree} is
    # {@code true} and the token index of the symbol returned by
    # {@link ANTLRErrorStrategy#recoverInline} is -1, the symbol is added to
    # the parse tree by calling {@link ParserRuleContext#addErrorNode}.</p>
    #
    # @return the matched symbol
    # @throws RecognitionException if the current input symbol did not match
    # a wildcard and the error strategy could not recover from the mismatched
    # symbol
    
    def matchWildcard()
        t = self.getCurrentToken()
        if t.type > 0 then
            self.errHandler.reportMatch(self)
            self.consume()
        else
            t = self.errHandler.recoverInline(self)
            if self.buildParseTrees and t.tokenIndex == -1 then
                # we must have conjured up a new token during single token insertion
                # if it's not the current symbol
                self.ctx.addErrorNode(t)
            end
        end
        return t
    end

    def getParseListeners
        @parseListeners
    end

    # Registers {@code listener} to receive events during the parsing process.
    #
    # <p>To support output-preserving grammar transformations (including but not
    # limited to left-recursion removal, automated left-factoring, and
    # optimized code generation), calls to listener methods during the parse
    # may differ substantially from calls made by
    # {@link ParseTreeWalker#DEFAULT} used after the parse is complete. In
    # particular, rule entry and exit events may occur in a different order
    # during the parse than after the parser. In addition, calls to certain
    # rule entry methods may be omitted.</p>
    #
    # <p>With the following specific exceptions, calls to listener events are
    # <em>deterministic</em>, i.e. for identical input the calls to listener
    # methods will be the same.</p>
    #
    # <ul>
    # <li>Alterations to the grammar used to generate code may change the
    # behavior of the listener calls.</li>
    # <li>Alterations to the command line options passed to ANTLR 4 when
    # generating the parser may change the behavior of the listener calls.</li>
    # <li>Changing the version of the ANTLR Tool used to generate the parser
    # may change the behavior of the listener calls.</li>
    # </ul>
    #
    # @param listener the listener to add
    #
    # @throws NullPointerException if {@code} listener is {@code null}
    #
    def addParseListener(listener)
        raise ReferenceError.new("listener is nil") if listener.nil? 
        @parseListeners = [] if @parseListeners.nil? 
        self.parseListeners.push(listener)
    end

    #
    # Remove {@code listener} from the list of parse listeners.
    #
    # <p>If {@code listener} is {@code null} or has not been added as a parse
    # listener, self method does nothing.</p>
    # @param listener the listener to remove
    #
    def removeParseListener(listener)
        return if @parseListeners.nil? 
        @parseListeners.delete(listener)
    end

    # Remove all parse listeners.
    def removeParseListeners
        @parseListeners = Array.new
    end

    # Notify any parse listeners of an enter rule event.
    def triggerEnterRuleEvent
        for listener in self.parseListeners do
             listener.enterEveryRule(self.ctx)
             self.ctx.enterRule(listener)
        end
    end

    #
    # Notify any parse listeners of an exit rule event.
    #
    # @see #addParseListener
    #
    def triggerExitRuleEvent
        # reverse order walk of listeners
        for listener in self.parseListeners.reverse do
            self.ctx.exitRule(listener)
            listener.exitEveryRule(self.ctx)
        end
    end


    def getTokenFactory
        return self.input.tokenSource.factory
    end

    # Tell our token source and error strategy about a new way to create tokens.#
    def setTokenFactory(factory)
        self.input.tokenSource.factory = factory
    end

    # The ATN with bypass alternatives is expensive to create so we create it
    # lazily.
    #
    # @throws UnsupportedOperationException if the current parser does not
    # implement the {@link #getSerializedATN()} method.
    #
    def getATNWithBypassAlts()
        serializedAtn = self.getSerializedATN()
        if serializedAtn.nil? 
            raise UnsupportedOperationException.new("The current parser does not support an ATN with bypass alternatives.")
        end
        result = self.bypassAltsAtnCache.get(serializedAtn)
        if result.nil? then
            deserializationOptions = ATNDeserializationOptions.new()
            deserializationOptions.generateRuleBypassTransitions = true
            result = ATNDeserializer(deserializationOptions).deserialize(serializedAtn)
            self.bypassAltsAtnCache[serializedAtn] = result
        end
        return result
    end

    # The preferred method of getting a tree pattern. For example, here's a
    # sample use:
    #
    # <pre>
    # ParseTree t = parser.expr();
    # ParseTreePattern p = parser.compileParseTreePattern("&lt;ID&gt;+0", MyParser.RULE_expr);
    # ParseTreeMatch m = p.match(t);
    # String id = m.get("ID");
    # </pre>
    #
    def compileParseTreePattern(pattern, patternRuleIndex, lexer=nil)
        if lexer.nil?  then
            if not self.getTokenStream().nil? then
                tokenSource = self.getTokenStream().getTokenSource()
            end
            lexer = tokenSource if tokenSource.kind_of? Lexer 
        end
        if lexer.nil? 
            raise UnsupportedOperationException.new("Parser can't discover a lexer to use")
        end
        m = ParseTreePatternMatcher.new(lexer, self)
        return m.compile(pattern, patternRuleIndex)
    end

    def getInputStream()
        return self.getTokenStream()
    end

    def setInputStream(input)
        self.setTokenStream(input)
    end

    def getTokenStream()
        return self.input
    end

    # Set the token stream and reset the parser.#
    def setTokenStream(input)
        self.input = nil
        self.reset()
        self.input = input
    end
    # Match needs to return the current input symbol, which gets put
    #  into the label for the associated token ref; e.g., x=ID.
    #
    def getCurrentToken()
        return self.input.LT(1)
    end

    def notifyErrorListeners(msg, offendingToken=nil ,e=nil) #RecognitionException 
        if offendingToken.nil?
            offendingToken = self.getCurrentToken()
        end
        @syntaxErrors = @syntaxErrors + 1
        line = offendingToken.line
        column = offendingToken.column
        listener = self.getErrorListenerDispatch()
        listener.syntaxError(self, offendingToken, line, column, msg, e)
    end
    #
    # Consume and return the {@linkplain #getCurrentToken current symbol}.
    #
    # <p>E.g., given the following input with {@code A} being the current
    # lookahead symbol, self function moves the cursor to {@code B} and returns
    # {@code A}.</p>
    #
    # <pre>
    #  A B
    #  ^
    # </pre>
    #
    # If the parser is not in error recovery mode, the consumed symbol is added
    # to the parse tree using {@link ParserRuleContext#addChild(Token)}, and
    # {@link ParseTreeListener#visitTerminal} is called on any parse listeners.
    # If the parser <em>is</em> in error recovery mode, the consumed symbol is
    # added to the parse tree using
    # {@link ParserRuleContext#addErrorNode(Token)}, and
    # {@link ParseTreeListener#visitErrorNode} is called on any parse
    # listeners.
    #
    def consume()
        o = self.getCurrentToken()
        if o.type != Token::EOF then
            self.getInputStream().consume()
        end
        hasListener = self.parseListeners and @parseListeners.length>0 
        if self.buildParseTrees or hasListener then
            if self.errHandler.inErrorRecoveryMode(self) then
                node = self.ctx.addErrorNode(o)
            else
                node = self.ctx.addTokenNode(o)
            end
            @parseListeners.each {|listener| listener.visitTerminal(node) }
        end
        return o
    end

    def addContextToParseTree()
        # add current context to parent if we have a parent
        if self.ctx.parentCtx then
            self.ctx.parentCtx.addChild(self.ctx)
        end
    end
    # Always called by generated parsers upon entry to a rule. Access field
    # {@link #ctx} get the current context.
    #
    def enterRule(localctx, state, ruleIndex)
        self.state = state
        self.ctx = localctx
        self.ctx.start = self.input.LT(1)
        self.addContextToParseTree() if self.buildParseTrees
        self.triggerEnterRuleEvent()
    end

    def exitRule()
        self.ctx.stop = self.input.LT(-1)
        # trigger event on ctx, before it reverts to parent
        self.triggerExitRuleEvent()
        self.state = self.ctx.invokingState
        self.ctx = self.ctx.parentCtx
    end

    def enterOuterAlt(localctx, altNum)
        # if we have new localctx, make sure we replace existing ctx
        # that is previous child of parse tree
        if self.buildParseTrees and self.ctx != localctx
            if not self.ctx.parentCtx.nil? then
                self.ctx.parentCtx.removeLastChild()
                self.ctx.parentCtx.addChild(localctx)
            end
        end
        self.ctx = localctx
    end

    # Get the precedence level for the top-most precedence rule.
    #
    # @return The precedence level for the top-most precedence rule, or -1 if
    # the parser context is not nested within a precedence rule.
    #
    def getPrecedence()
        if @precedenceStack.length==0
            return -1
        else
            return @precedenceStack[-1]
        end
    end

    def enterRecursionRule(localctx, state, ruleIndex, precedence)
        self.state = state
        self.precedenceStack.push(precedence)
        self.ctx = localctx
        self.ctx.start = self.input.LT(1)
        self.triggerEnterRuleEvent() # simulates rule entry for left-recursive rules
    end

    #
    # Like {@link #enterRule} but for recursive rules.
    #
    def pushNewRecursionContext(localctx, state, ruleIndex)
        previous = self.ctx
        previous.parentCtx = localctx
        previous.invokingState = state
        previous.stop = self.input.LT(-1)

        self.ctx = localctx
        self.ctx.start = previous.start
        self.ctx.addChild(previous) if self.buildParseTrees
        self.triggerEnterRuleEvent() # simulates rule entry for left-recursive rules
    end

    def unrollRecursionContexts(parentCtx)
        self.precedenceStack.pop()
        self.ctx.stop = self.input.LT(-1)
        retCtx = self.ctx # save current ctx (return value)
        # unroll so ctx is as it was before call to recursive method
        if not self.parseListeners.empty? then
            while self.ctx != parentCtx do
                self.triggerExitRuleEvent()
                self.ctx = self.ctx.parentCtx
            end
        else
            self.ctx = parentCtx
        end
        # hook into tree
        retCtx.parentCtx = parentCtx

        if self.buildParseTrees and parentCtx then
            # add return ctx into invoking rule's tree
            parentCtx.addChild(retCtx)
        end
    end
    def getInvokingContext(ruleIndex)
        ctx = self.ctx
        while not ctx.nil? do
            if ctx.ruleIndex == ruleIndex
                return ctx
            end
            ctx = ctx.parentCtx
        end
        return nil
    end


    def precpred(localctx, precedence)
        return precedence >= self.precedenceStack[-1]
    end

    def inContext(context)
        # TODO: useful in parser?
        return false
    end

    #
    # Checks whether or not {@code symbol} can follow the current state in the
    # ATN. The behavior of self method is equivalent to the following, but is
    # implemented such that the complete context-sensitive follow set does not
    # need to be explicitly constructed.
    #
    # <pre>
    # return getExpectedTokens().contains(symbol);
    # </pre>
    #
    # @param symbol the symbol type to check
    # @return {@code true} if {@code symbol} can follow the current state in
    # the ATN, otherwise {@code false}.
    #
    def isExpectedToken(symbol)
        atn = self.interp.atn
        ctx = self.ctx
        s = atn.states[self.state]
        following = atn.nextTokens(s)
#        print "\nisExpectedToken: #{following.toString(tokenNames)}: #{s}"
        if following.member?(symbol) then
#            puts " true "
            return true
        end
        if not following.member? Token.EPSILON then
#            puts " FAIL "
            return false
        end
        while ctx and ctx.invokingState >= 0 and following.member?(Token.EPSILON) do
            invokingState = atn.states[ctx.invokingState]
            rt = invokingState.transitions[0]
            following = atn.nextTokens(rt.followState)
            return true if following.member?(symbol)
            ctx = ctx.parentCtx
        end
        if following.member?( Token.EPSILON) and symbol == Token.EOF
            return true
        else
            return false
        end
    end
    # Computes the set of input symbols which could follow the current parser
    # state and context, as given by {@link #getState} and {@link #getContext},
    # respectively.
    #
    # @see ATN#getExpectedTokens(int, RuleContext)
    #
    def getExpectedTokens()
        return self.interp.atn.getExpectedTokens(self.state, self.ctx)
    end

    def getExpectedTokensWithinCurrentRule()
        atn = self.interp.atn
        s = atn.states[self.state]
        return atn.nextTokens(s)
    end

    # Get a rule's index (i.e., {@code RULE_ruleName} field) or -1 if not found.#
    def getRuleIndex(ruleName)
        ruleIndex = self.getRuleIndexMap().get(ruleName)
        if ruleIndex then
            return ruleIndex
        else
            return -1
        end
    end

    # Return List&lt;String&gt; of the rule names in your parser instance
    #  leading up to a call to the current rule.  You could override if
    #  you want more details such as the file/line info of where
    #  in the ATN a rule is invoked.
    #
    #  this is very useful for error messages.
    #
    def getRuleInvocationStack(p=nil)
        p = self.ctx if p.nil? 
        stack = Array.new
        while p do
            # compute what follows who invoked us
            ruleIndex = p.getRuleIndex()
            if ruleIndex<0
                stack.push("n/a")
            else
                stack.push(self.ruleNames[ruleIndex])
            end
            p = p.parentCtx
        end
        return stack
    end
    # For debugging and other purposes.#
    def getDFAStrings
        self.interp.decisionToDFA.map {|dfa| dfa.to_s  }
    end
    # For debugging and other purposes.#
    def dumpDFA()
        seenOne = false
        self.interp.decisionToDFA.each {|dfa| 
            if dfa.states.length > 0
                puts "Decision #{dfa.decision}:"
                puts dfa.toString(self.tokenNames)
            end
       }
    end
    def getSourceName
        return self.input.sourceName
    end

    # During a parse is sometimes useful to listen in on the rule entry and exit
    #  events as well as token matches. self is for quick and dirty debugging.
    #
    def setTrace(trace)
        if not trace then
            self.removeParseListener(self.tracer)
            self.tracer = nil
        else
            if self.tracer 
                self.removeParseListener(self.tracer)
            end
            self.tracer = TraceListener.new(self)
            self.addParseListener(self.tracer)
        end
    end
end
