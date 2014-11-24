# A token has properties: text, type, line, character position in the line
# (so we can ignore tabs), token channel, index, and source from which
# we obtained this token.

class Token
    include JavaSymbols

    INVALID_TYPE = 0
    # During lookahead operations, this "token" signifies we hit rule end ATN state
    # and did not follow it despite needing to.
    EPSILON = -2
    MIN_USER_TOKEN_TYPE = 1
    EOF = -1
    # All tokens go to the parser (unless skip() is called in that rule)
    # on a particular "channel".  The parser tunes to a particular channel
    # so that whitespace etc... can go to the parser on a "hidden" channel.
    DEFAULT_CHANNEL = 0
    # Anything on different channel than DEFAULT_CHANNEL is not parsed
    # by parser.
    HIDDEN_CHANNEL = 1

    attr_accessor :source, :type, :channel, :start, :stop, :tokenIndex
    attr_accessor :line, :column , :text
# A token has properties: text, type, line, character position in the line
# (so we can ignore tabs), token channel, index, and source from which
# we obtained this token.
    def initialize()
        self.source = nil
        self.type = nil       # token type of the token
        self.channel = nil    # The parser ignores everything not on DEFAULT_CHANNEL
        self.start = -1       # optional; return -1 if not implemented.
        self.stop = -1        # optional; return -1 if not implemented.
        self.tokenIndex = nil # from 0..n-1 of the token object in the input stream
        self.line = nil       # line=1..n of the 1st character
        self.column = nil     # beginning of the line at which it occurs, 0..n-1
    end
    # Explicitly set the text for this token. If {code text} is not
    # {@code null}, then {@link #getText} will return this value rather than
    # extracting the text from the input.
    #
    # @param text The explicit text of the token, or {@code null} if the text
    # should be obtained from the input along with the start and stop indexes
    # of the token.

    def getTokenSource()
        return self.source[0]
    end

    def getInputStream()
        return self.source[1]
    end
end

class CommonToken < Token
    # An empty {@link Pair} which is used as the default value of
    # {@link #source} for tokens that do not have a source.
    EMPTY_SOURCE = [nil, nil]

    def initialize(source = EMPTY_SOURCE, type = nil, channel=Token.DEFAULT_CHANNEL, start=-1, stop=-1)
        super()
        self.source = source
        self.type = type
        self.channel = channel
        self.start = start
        self.stop = stop
        self.tokenIndex = -1
        if not source[0].nil? then
            self.line = source[0].line
            self.column = source[0].column
        else
            self.column = -1
            self.line = nil
        end
    end
    # Constructs a new {@link CommonToken} as a copy of another {@link Token}.
    #
    # <p>
    # If {@code oldToken} is also a {@link CommonToken} instance, the newly
    # constructed token will share a reference to the {@link #text} field and
    # the {@link Pair} stored in {@link #source}. Otherwise, {@link #text} will
    # be assigned the result of calling {@link #getText}, and {@link #source}
    # will be constructed from the result of {@link Token#getTokenSource} and
    # {@link Token#getInputStream}.</p>
    #
    # @param oldToken The token to copy.
     #
    def clone()
#        t = CommonToken(self.source, self.type, self.channel, self.start, self.stop)
#        t.tokenIndex = self.tokenIndex
#        t.line = self.line
#        t.column = self.column
#        t.text = self.text
#        return t
      raise NotImplementedError.new("Token.clone not implemented")
    end
    def text()
        return @text if @text
        input = self.getInputStream()
        return nil if input.nil? 
        n = input.size
        if self.start < n and self.stop < n then
            return input.getText(self.start, self.stop)
        else
            return '<EOF>'
        end
    end

    def to_s
      txt = self.text()
      if txt.nil? then
        txt = "<no text>"
      else 
        txt = txt.gsub("\n","\\n").gsub("\r","\\r").gsub("\t","\\t")
      end
      if self.channel > 0 then
        c = ",channel=#{channel}"
      else
        c = ""
      end
      "[@#{tokenIndex},#{start}:#{stop}='#{txt}',<#{type}>#{c},#{line}:#{column}]"
    end
    def inspect
      to_s
    end
end
