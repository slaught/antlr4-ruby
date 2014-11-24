
class BufferedTokenStream < TokenStream

    attr_accessor :tokenSource, :tokens, :index,:fetchedEOF 
    def initialize(_tokenSource)
        # The {@link TokenSource} from which tokens for this stream are fetched.
        @tokenSource = _tokenSource
        # A collection of all tokens fetched from the token source. The list is
        # considered a complete view of the input once {@link #fetchedEOF} is set
        # to {@code true}.
        self.tokens = Array.new

        # The index into {@link #tokens} of the current token (next token to
        # {@link #consume}). {@link #tokens}{@code [}{@link #p}{@code ]} should be
        # {@link #LT LT(1)}.
        #
        # <p>This field is set to -1 when the stream is first constructed or when
        # {@link #setTokenSource} is called, indicating that the first token has
        # not yet been fetched from the token source. For additional information,
        # see the documentation of {@link IntStream} for a description of
        # Initializing Methods.</p>
        self.index = -1

        # Indicates whether the {@link Token#EOF} token has been fetched from
        # {@link #tokenSource} and added to {@link #tokens}. This field improves
        # performance for the following cases
        #
        # <ul>
        # <li>{@link #consume}: The lookahead check in {@link #consume} to prevent
        # consuming the EOF symbol is optimized by checking the values of
        # {@link #fetchedEOF} and {@link #p} instead of calling {@link #LA}.</li>
        # <li>{@link #fetch}: The check to prevent adding multiple EOF symbols into
        # {@link #tokens} is trivial with this field.</li>
        # <ul>
        self.fetchedEOF = false
    end

    def mark
        return 0
    end
    
    def release(marker)
        # no resources to release
    end
    
    def reset()
        self.seek(0)
    end
    def seek( index)
        self.lazyInit()
        self.index = self.adjustSeekIndex(index)
    end
    def get(index)
        self.lazyInit()
        return self.tokens[index]
    end
    def consume()
        skipEofCheck = false
        if self.index >= 0 then
            if self.fetchedEOF then
                # the last token in tokens is EOF. skip check if p indexes any
                # fetched token except the last.
                skipEofCheck = self.index < self.tokens.length - 1
            else
               # no EOF token in tokens. skip check if p indexes a fetched token.
                skipEofCheck = self.index < self.tokens.length
            end
        else
            # not yet initialized
            skipEofCheck = false
        end
        if not skipEofCheck and self.LA(1) == Token::EOF then
            raise IllegalStateException.new("cannot consume EOF")
        end
        if self.sync(self.index + 1) then
            self.index = self.adjustSeekIndex(self.index + 1)
        end
    end
    # Make sure index {@code i} in tokens has a token.
    #
    # @return {@code true} if a token is located at index {@code i}, otherwise
    #    {@code false}.
    # @see #get(int i)
    #/
    def sync(i)
        #assert i >= 0
        n = i - self.tokens.length + 1 # how many more elements we need?
        if n > 0 then
            fetched = self.fetch(n)
            return fetched >= n
        end
        return true
    end
    # Add {@code n} elements to buffer.
    #
    # @return The actual number of elements added to the buffer.
    #/
    def fetch(n)
        return 0 if self.fetchedEOF
        1.upto(n) do |i| # for i in 0..n-1 do
            t = self.tokenSource.nextToken()
            t.tokenIndex = self.tokens.length
            self.tokens.push(t)
            if t.type==Token::EOF then
                self.fetchedEOF = true
                return i  #  i + 1
            end
        end
        return n
    end

    # Get all tokens from start..stop inclusively#/
    def getTokens(start, stop, types=nil)
        if start<0 or stop<0 then
            return  nil
        end
        self.lazyInit()
        subset = Array.new
        if stop >= self.tokens.length
            stop = self.tokens.length-1
        end
        for i in start..stop-1 do
            t = self.tokens[i]
            if t.type==Token::EOF
                break
            end
            if (types.nil? or types.member?(t.type)) then
                subset.push(t)
            end
        end
        return subset
    end
    def LA(i)
        return self.LT(i).type
    end
    def LB(k)
        return nil if (self.index-k) < 0
        return self.tokens[self.index-k]
    end
    def LT(k)
        self.lazyInit()
        return nil if k==0
        return self.LB(-k) if k < 0
        i = self.index + k - 1
        self.sync(i)
        if i >= self.tokens.length then # return EOF token
            # EOF must be last token
            return self.tokens[self.tokens.length-1]
        end
        return self.tokens[i]
    end
    # Allowed derived classes to modify the behavior of operations which change
    # the current stream position by adjusting the target token index of a seek
    # operation. The default implementation simply returns {@code i}. If an
    # exception is thrown in this method, the current stream index should not be
    # changed.
    #
    # <p>For example, {@link CommonTokenStream} overrides this method to ensure that
    # the seek target is always an on-channel token.</p>
    #
    # @param i The target token index.
    # @return The adjusted target token index.

    def adjustSeekIndex(i)
        return i
    end

    def lazyInit
        if self.index == -1 then
            self.setup()
        end
    end

    def setup()
        self.sync(0)
        self.index = self.adjustSeekIndex(0)
    end

    # Reset this token stream by setting its token source.#/
    def setTokenSource(tokenSource)
        self.tokenSource = tokenSource
        self.tokens = []
        self.index = -1
    end



    # Given a starting index, return the index of the next token on channel.
    #  Return i if tokens[i] is on channel.  Return -1 if there are no tokens
    #  on channel between i and EOF.
    #/
    def nextTokenOnChannel(i, channel)
        self.sync(i)
        return -1 if i>=self.tokens.length 
        token = self.tokens[i]
        while token.channel!=self.channel do
            return -1 if token.type==Token::EOF
            i = i + 1
            self.sync(i)
            token = self.tokens[i]
        end
        return i
    end
    # Given a starting index, return the index of the previous token on channel.
    #  Return i if tokens[i] is on channel. Return -1 if there are no tokens
    #  on channel between i and 0.
    def previousTokenOnChannel(i, channel)
        while i>=0 and self.tokens[i].channel!=channel do
            i = i - 1
        end
        return i
    end
    # Collect all tokens on specified channel to the right of
    #  the current token up until we see a token on DEFAULT_TOKEN_CHANNEL or
    #  EOF. If channel is -1, find any non default channel token.
    def getHiddenTokensToRight(tokenIndex, channel=-1)
        self.lazyInit()
        if self.tokenIndex<0 or tokenIndex>=self.tokens.length then
            raise Exception.new("#{tokenIndex} not in 0..#{self.tokens.length-1}")
        end
        nextOnChannel = self.nextTokenOnChannel(tokenIndex + 1, Lexer.DEFAULT_TOKEN_CHANNEL)
        from_ = tokenIndex+1
        # if none onchannel to right, nextOnChannel=-1 so set to = last token
        if nextOnChannel==-1 
            to = self.tokens.length-1
        else 
            to = nextOnChannel
        end
        return self.filterForChannel(from_, to, channel)
    end

    # Collect all tokens on specified channel to the left of
    #  the current token up until we see a token on DEFAULT_TOKEN_CHANNEL.
    #  If channel is -1, find any non default channel token.
    def getHiddenTokensToLeft(tokenIndex, channel=-1)
        self.lazyInit()
        if tokenIndex<0 or tokenIndex>=self.tokens.length
            raise Exception.new("#{tokenIndex} not in 0..#{self.tokens.length-1}")
        end
        prevOnChannel = self.previousTokenOnChannel(tokenIndex - 1, Lexer.DEFAULT_TOKEN_CHANNEL)
        return nil if prevOnChannel == tokenIndex - 1
        
        # if none on channel to left, prevOnChannel=-1 then from=0
        from_ = prevOnChannel+1
        to = tokenIndex-1
        return self.filterForChannel(from_, to, channel)
    end

    def filterForChannel(left, right, channel)
        hidden = []
        for i in left..right do
            t = self.tokens[i]
            if channel==-1 then
                if t.channel!= Lexer.DEFAULT_TOKEN_CHANNEL
                    hidden.push(t)
                end
            elsif t.channel==channel then
                    hidden.push(t)
            end
        end
        return nil if hidden.length==0 
        return hidden
    end

    def getSourceName
        return self.tokenSource.getSourceName()
    end

    # Get the text of all tokens in this buffer.#/
    def getText(interval=nil)
        self.lazyInit()
        self.fill()
        if interval.nil?
            interval = [0, self.tokens.length-1]
        end
        start = interval[0]
        if start.kind_of? Token
            start = start.tokenIndex
        end
        stop = interval[1]
        if stop.kind_of? Token
            stop = stop.tokenIndex
        end
        if start.nil? or stop.nil? or start<0 or stop<0
            return ""
        end
        if stop >= self.tokens.length
            stop = self.tokens.length-1
        end
        StringIO.open  do |buf|
            for i in start..stop do
                t = self.tokens[i]
                break if t.type==Token::EOF
                buf.write(t.text)
            end
            return buf.string()
        end
    end
    # Get all tokens from lexer until EOF#/
    def fill
        self.lazyInit()
        while fetch(1000)==1000 do
            nil
        end
    end
end
