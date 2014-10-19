#from antlr4.RuleContext import RuleContext
#from antlr4.Token import Token
#from antlr4.error.ErrorListener import ProxyErrorListener, ConsoleErrorListener
require 'RuleContext'
require 'Token'
require 'error/ErrorListener'
require 'error'


class Recognizer

    attr_accessor :listeners, :interp, :stateNumber
    attr_accessor :tokenTypeMapCache, :ruleIndexMapCache 
    def initialize
        @listeners = [ ConsoleErrorListener.INSTANCE ]
        @interp = nil
        @stateNumber = -1
        @tokenTypeMapCache = Hash.new
        @ruleIndexMapCache = Hash.new
    end

    def extractVersion(version)
        pos = version.find(".")
        major = version[0,pos-1]
        version = version[pos+1,version.length]
        pos = version.find(".")
        if pos==-1
            pos = version.find("-")
        end
        if pos==-1
            pos = version.length
        end
        minor = version[0,pos-1]
        return major, minor
    end

    def checkVersion(toolVersion)
        runtimeVersion = "4.4.1"
        rvmajor, rvminor = self.extractVersion(runtimeVersion)
        tvmajor, tvminor = self.extractVersion(toolVersion)
        if rvmajor!=tvmajor or rvminor!=tvminor
            puts "ANTLR runtime and generated code versions disagree: #{runtimeVersion}!=#{toolVersion}"
        end
    end

    def addErrorListener(listener)
        self.listeners.push(listener)
    end
    def getTokenTypeMap
        tokenNames = self.getTokenNames()
        if tokenNames.nil? then
            raise UnsupportedOperationException.new("The current recognizer does not provide a list of token names.")
        end
        result = self.tokenTypeMapCache.get(tokenNames)
        if result.nil? 
            result = tokenNames.zip(0..tokenNames.length) 
            result["EOF"] = Token.EOF
            self.tokenTypeMapCache[tokenNames] = result
        end
        return result
    end
    # Get a map from rule names to rule indexes.
    #
    # <p>Used for XPath and tree pattern compilation.</p>
    #
    def getRuleIndexMap
        ruleNames = self.getRuleNames()
        if ruleNames.nil? then
            raise UnsupportedOperationException.new("The current recognizer does not provide a list of rule names.")
        end
        result = self.ruleIndexMapCache.get(ruleNames)
        if result.nil? 
            result = ruleNames.zip( 0..ruleNames.length)
            self.ruleIndexMapCache[ruleNames] = result
        end
        return result
    end

    def getTokenType(tokenName)
        ttype = self.getTokenTypeMap().get(tokenName)
        if not ttype.nil? then
            return ttype
        else
            return Token.INVALID_TYPE
        end
    end

    # What is the error header, normally line/character position information?#
    def getErrorHeader(e) # :RecognitionException):
        line = e.getOffendingToken().line
        column = e.getOffendingToken().column
        return "line #{line}:#{column}"
    end


    # How should a token be displayed in an error message? The default
    #  is to display just the text, but during development you might
    #  want to have a lot of information spit out.  Override in that case
    #  to use t.toString() (which, for CommonToken, dumps everything about
    #  the token). This is better than forcing you to override a method in
    #  your token objects because you don't have to go modify your lexer
    #  so that it creates a new Java type.
    #
    # @deprecated This method is not called by the ANTLR 4 Runtime. Specific
    # implementations of {@link ANTLRErrorStrategy} may provide a similar
    # feature when necessary. For example, see
    # {@link DefaultErrorStrategy#getTokenErrorDisplay}.
    #
    def getTokenErrorDisplay(t)
        return "<no token>" if t.nil? 
        s = t.text
        if s.nil? 
            if t.type==Token.EOF
                s = "<EOF>"
            else
                s = "<" + str(t.type) + ">"
            end
        end
        s = s.sub("\n","\\n")
        s = s.sub("\r","\\r")
        s = s.sub("\t","\\t")
        return "'" + s + "'"
    end

    def getErrorListenerDispatch
        return ProxyErrorListener.new(self.listeners)
    end

    # subclass needs to override these if there are sempreds or actions
    # that the ATN interp needs to execute
    def sempred(localctx, ruleIndex, actionIndex)
        return true
    end

    def precpred(localctx, precedence)
        return true
    end

    def state
        return self.stateNumber
    end

    # Indicate that the recognizer has changed internal state that is
    #  consistent with the ATN state passed in.  This way we always know
    #  where we are in the ATN as the parser goes along. The rule
    #  context objects form a stack that lets us see the stack of
    #  invoking rules. Combine this and we have complete ATN
    #  configuration information.

    def state=(atnState)
        self.stateNumber = atnState
    end
end

#import unittest
#class Test(unittest.TestCase):
#    def testVersion(self):
#        major, minor = Recognizer().extractVersion("1.2")
#        self.assertEqual("1", major)
#        self.assertEqual("2", minor)
#        major, minor = Recognizer().extractVersion("1.2.3")
#        self.assertEqual("1", major)
#        self.assertEqual("2", minor)
#        major, minor = Recognizer().extractVersion("1.2-snapshot")
#        self.assertEqual("1", major)
#        self.assertEqual("2", minor)
