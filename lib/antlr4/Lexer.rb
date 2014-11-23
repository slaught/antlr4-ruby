# A lexer is recognizer that draws input symbols from a character stream.
#  lexer grammars result in a subclass of self object. A Lexer object
#  uses simplified match() and error recovery mechanisms in the interest
#  of speed.

class Lexer < TokenSource
    include JavaSymbols
    DEFAULT_MODE = 0
    MORE = -2
    SKIP = -3

    DEFAULT_TOKEN_CHANNEL = Token.DEFAULT_CHANNEL
    HIDDEN = Token.HIDDEN_CHANNEL
    MIN_CHAR_VALUE = "\u0000"
    MAX_CHAR_VALUE = "\uFFFE"

    attr_accessor :input, :factory, :tokenFactorySourcePair #, :interp
    attr_accessor :token, :tokenStartCharIndex, :tokenStartLine, :tokenStartColumn 
    attr_accessor  :hitEOF, :channel,:type, :modeStack, :mode, :text

    def initialize(input)
        super()
        @input = input
        @factory = CommonTokenFactory.DEFAULT
        @tokenFactorySourcePair = [self, input]

        @interp = nil # child classes must populate this
        
        # The goal of all lexer rules/methods is to create a token object.
        #  self is an instance variable as multiple rules may collaborate to
        #  create a single token.  nextToken will return self object after
        #  matching lexer rule(s).  If you subclass to allow multiple token
        #  emissions, then set self to the last token to be matched or
        #  something nonnull so that the auto token emit mechanism will not
        #  emit another token.
        @token = nil

        # What character index in the stream did the current token start at?
        #  Needed, for example, to get the text for current token.  Set at
        #  the start of nextToken.
        @tokenStartCharIndex = -1

        # The line on which the first character of the token resides#/
        @tokenStartLine = -1

        # The character position of first character within the line#/
        @tokenStartColumn = -1

        # Once we see EOF on char stream, next token will be EOF.
        #  If you have DONE : EOF ; then you see DONE EOF.
        @hitEOF = false

        # The channel number for the current token#/
        @channel = Token.DEFAULT_CHANNEL

        # The token type for the current token#/
        @type = Token.INVALID_TYPE

        @modeStack = Array.new
        @mode = Lexer.DEFAULT_MODE

        # You can set the text for the current token to override what is in
        #  the input char buffer.  Use setText() or can set self instance var.
        #/
        @text = nil
    end

    def reset
        # wack Lexer state variables
        if not self.input.nil? then 
            self.input.seek(0) # rewind the input
        end
        self.token = nil
        self.type = Token.INVALID_TYPE
        self.channel = Token.DEFAULT_CHANNEL
        self.tokenStartCharIndex = -1
        self.tokenStartColumn = -1
        self.tokenStartLine = -1
        self.text = nil

        self.hitEOF = false
        self.mode = Lexer.DEFAULT_MODE
        self.modeStack = Array.new

        self.interp.reset()
    end

    # Return a token from self source; i.e., match a token on the char
    #  stream.
    def nextToken
        if self.input.nil? 
            raise IllegalStateException.new("nextToken requires a non-null input stream.")
        end

        # Mark start location in char stream so unbuffered streams are
        # guaranteed at least have text of current token
        tokenStartMarker = self.input.mark()
        begin
            while true do 
                if self.hitEOF then
                    self.emitEOF()
                    return self.token
                end
                self.token = nil
                self.channel = Token.DEFAULT_CHANNEL
                self.tokenStartCharIndex = self.input.index
                self.tokenStartColumn = self.interp.column
                self.tokenStartLine = self.interp.line
                self.text = nil
                continueOuter = false
                while true do 
                    self.type = Token.INVALID_TYPE
                    ttype = Lexer::SKIP
                    begin
                        ttype = self.interp.match(self.input, self.mode)
                    rescue LexerNoViableAltException => e
                        self.notifyListeners(e)		# report error
                        self.recover(e)
                    end
                    if self.input.LA(1)==Token::EOF then
                        self.hitEOF = true
                    end
                    if self.type == Token.INVALID_TYPE
                        self.type = ttype
                  
                    end
                    if self.type == Lexer::SKIP
                        continueOuter = true
                        break
                    end
                    if self.type!= Lexer::MORE
                        break
                    end
                end
                next if continueOuter
                self.emit() if self.token.nil?
                return self.token
            end
        ensure  
            # make sure we release marker after match or
            # unbuffered char stream will keep buffering
            self.input.release(tokenStartMarker)
        end
    end

    # Instruct the lexer to skip creating a token for current lexer rule
    #  and look for another token.  nextToken() knows to keep looking when
    #  a lexer rule finishes with token set to SKIP_TOKEN.  Recall that
    #  if token==null at end of any token rule, it creates one for you
    #  and emits it.
    #/
    def skip
        self.type = Lexer::SKIP
    end
    def more
        self.type = Lexer::MORE
    end
    def pushMode(m)
        if self.interp.debug then
            puts "pushMode #{m}"
        end
        self.modeStack.push(self.mode)
        self.mode = m
    end
    def popMode
        if self.modeStack.empty? then
            raise Exception.new("Empty Stack")
        end
        if self.interp.debug then
            puts  "popMode back to #{self.modeStack.slice(0,self.modeStack.length-1)}"
        end
        self.mode = self.odeStack.pop() 
        return self.mode
    end

    # Set the char stream and reset the lexer#/
    def inputStream
        return self.input
    end

    def inputStream=(input)
        self.input = nil
        self.tokenFactorySourcePair = [self, nil]
        self.reset()
        self.input = input
        self.tokenFactorySourcePair = [self, self.input]
    end

    def sourceName
        return self.input.sourceName
    end

    # By default does not support multiple emits per nextToken invocation
    #  for efficiency reasons.  Subclass and override self method, nextToken,
    #  and getToken (to push tokens into a list and pull from that list
    #  rather than a single variable as self implementation does).
    #/
    def emitToken(token)
        self.token = token
    end

    # The standard method called to automatically emit a token at the
    #  outermost lexical rule.  The token object should point into the
    #  char buffer start..stop.  If there is a text override in 'text',
    #  use that to set the token's text.  Override self method to emit
    #  custom Token objects or provide a new factory.
    #/
    def emit
        t = self.factory.create(self.tokenFactorySourcePair, self.type, self.text, self.channel, self.tokenStartCharIndex,
                                 self.getCharIndex()-1, self.tokenStartLine, self.tokenStartColumn)
        self.emitToken(t)
        return t
    end

    def emitEOF()
        cpos = self.column
        # The character position for EOF is one beyond the position of
        # the previous token's last character
        if not self.token.nil? then
            n = self.token.stop - self.token.start + 1
            cpos = self.token.column + n
        end
        eof = self.factory.create(self.tokenFactorySourcePair, Token.EOF, nil, Token.DEFAULT_CHANNEL, self.input.index,
                                   self.input.index-1, self.line, cpos)
        self.emitToken(eof)
        return eof
    end

    def line
        return self.interp.line
    end

    def line=(line)
        self.interp.line = line
    end

    def column
        return self.interp.column
    end

    def column=(column)
        self.interp.column = column
    end

    # What is the index of the current character of lookahead?#/
    def getCharIndex()
        return self.input.index
    end

    # Return the text matched so far for the current token or any
    #  text override.
    def text
        if not @text.nil? then
            @text
        else
            self.interp.getText(self.input)
        end
    end

    # Set the complete text of self token; it wipes any previous
    #  changes to the text.
    def text=(txt)
        @text = txt
    end

    # Return a list of all Token objects in input char stream.
    #  Forces load of all tokens. Does not include EOF token.
    #/
    def getAllTokens
        tokens = Array.new
        t = self.nextToken()
        while t.type!=Token.EOF do
            tokens.push(t)
            t = self.nextToken()
        end
        return tokens
    end
    def notifyListeners(e) # :LexerNoViableAltException):
        start = self.tokenStartCharIndex
        stop = self.input.index
        text = self.input.getText(start, stop)
        msg = "token recognition error at: '#{self.getErrorDisplay(text) }'"
        listener = self.getErrorListenerDispatch()
        listener.syntaxError(self, nil, self.tokenStartLine, self.tokenStartColumn, msg, e)
    end

    def getErrorDisplay(s)
        StringIO.open  do |buf|
            s.chars.each{|c| buf.write(self.getErrorDisplayForChar(c)) }
            return buf.string()
        end
    end
    def getErrorDisplayForChar(c)
        if c[0].ord==Token.EOF then
            return "<EOF>"
        elsif c=='\n'
            return "\\n"
        elsif c=='\t'
            return "\\t"
        elsif c=='\r'
            return "\\r"
        else
            return c
        end
    end
    def getCharErrorDisplay(c)
        return "'" + self.getErrorDisplayForChar(c) + "'"
    end

    # Lexers can normally match any char in it's vocabulary after matching
    #  a token, so do the easy thing and just kill a character and hope
    #  it all works out.  You can instead use the rule invocation stack
    #  to do sophisticated error recovery if you are in a fragment rule.
    #/
    def recover(re) # :RecognitionException):
        if self.input.LA(1) != Token.EOF then
            if re.kind_of?  LexerNoViableAltException then
                    # skip a char and try again
                    self.interp.consume(self.input)
            else
                # TODO: Do we lose character or line position information?
                self.input.consume()
            end
        end
    end
    def getRuleNames
        self.ruleNames
    end
end

