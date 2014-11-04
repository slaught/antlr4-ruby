require 'double_key_map'
require 'java_symbols'
require 'uuid'

require 'stringio'
require 'set'
require 'forwardable'

require 'antlr4/base'
require 'antlr4/version'

require 'antlr4/Token'
require 'antlr4/InputStream'
require 'antlr4/FileStream'
require 'antlr4/TokenStream'

require 'antlr4/error'
require 'antlr4/error/ErrorListener'
require 'antlr4/error/DiagnosticErrorListener'
require 'antlr4/error/ErrorStrategy'

require 'antlr4/BufferedTokenStream'
require 'antlr4/CommonTokenStream'

require 'antlr4/IntervalSet'

require 'antlr4/tree/Trees'
require 'antlr4/tree/Tree'
require 'antlr4/tree/TokenTagToken'
require 'antlr4/tree/RuleTagToken'
require 'antlr4/tree/ParseTreeMatch'
require 'antlr4/tree/ParseTreePatternMatcher'
# 
require 'antlr4/Recognizer'
require 'antlr4/TokenSource'
require 'antlr4/ListTokenSource'
require 'antlr4/TokenFactory'
require 'antlr4/CommonTokenFactory'

require 'antlr4/RuleContext'
require 'antlr4/ParserRuleContext'
require 'antlr4/PredictionContext'

require 'antlr4/LL1Analyzer'

require 'antlr4/dfa/DFA'
require 'antlr4/dfa/DFAState'
require 'antlr4/dfa/DFASerializer'

require 'antlr4/atn/ATNType'
require 'antlr4/atn/ATNState'
require 'antlr4/atn/ATN'
require 'antlr4/atn/ATNConfig'
require 'antlr4/atn/ATNConfigSet'
require 'antlr4/atn/Transition'
require 'antlr4/atn/ATNSimulator'
require 'antlr4/atn/SemanticContext'
require 'antlr4/atn/LexerAction'
require 'antlr4/atn/LexerActionExecutor'
require 'antlr4/atn/PredictionMode'
require 'antlr4/atn/ATNDeserializationOptions'
require 'antlr4/atn/LexerATNSimulator'
require 'antlr4/atn/ParserATNSimulator'
require 'antlr4/atn/ATNDeserializer'

require 'antlr4/Parser'
require 'antlr4/ParserInterpreter'
require 'antlr4/Lexer'


__END__
CommonTokenFactory.rb:3:require 'Token'
CommonTokenFactory.rb:5:require 'TokenFactory'

FileStream.rb:7:require 'InputStream'
InputStream.rb:6:require 'Token'
IntervalSet.rb:3:require 'Token'
IntervalSet.rb:4:require 'set'
IntervalSet.rb:19:require 'forwardable'
LL1Analyzer.rb:3:require 'Token'
LL1Analyzer.rb:11:require 'set'
Lexer.rb:15:require 'CommonTokenFactory'
Lexer.rb:16:require 'atn/LexerATNSimulator'
Lexer.rb:17:require 'InputStream'
Lexer.rb:18:require 'Recognizer'
Lexer.rb:19:require 'error'
Lexer.rb:20:require 'Token'
Lexer.rb:21:require 'TokenSource'
Lexer.rb:23:require 'java_symbols' 
Lexer.rb:111:            raise IllegalStateException.new("nextToken requires a non-null input stream.")
ListTokenSource.rb:13:require 'CommonTokenFactory'
ListTokenSource.rb:14:require 'TokenSource'
ListTokenSource.rb:15:require 'Token'
Parser.rb:1:require 'TokenStream'
Parser.rb:2:require 'TokenFactory'
Parser.rb:3:require 'error'
Parser.rb:4:require 'error/ErrorStrategy'
Parser.rb:5:require 'InputStream'
Parser.rb:6:require 'Recognizer'
Parser.rb:7:require 'RuleContext'
Parser.rb:8:require 'ParserRuleContext'
Parser.rb:9:require 'Token'
Parser.rb:10:require 'Lexer'
Parser.rb:11:require 'tree/ParseTreePatternMatcher'
Parser.rb:12:require 'tree/Tree'
Parser.rb:19:require 'java_symbols'
ParserInterpreter.rb:27:require 'TokenStream'
ParserInterpreter.rb:28:require 'Parser'
ParserInterpreter.rb:29:require 'ParserRuleContext'
ParserInterpreter.rb:30:require 'Token'
ParserInterpreter.rb:31:require 'error'
ParserInterpreter.rb:33:require 'set'
ParserRuleContext.rb:24:require 'RuleContext'
ParserRuleContext.rb:25:require 'Token'
ParserRuleContext.rb:26:require 'tree/Tree'
PredictionContext.rb:6:require 'RuleContext'
PredictionContext.rb:7:require 'double_key_map'
Recognizer.rb:4:require 'RuleContext'
Recognizer.rb:5:require 'Token'
Recognizer.rb:6:require 'error/ErrorListener'
Recognizer.rb:7:require 'error'
RuleContext.rb:22:require 'stringio'
RuleContext.rb:25:require 'tree/Tree'
RuleContext.rb:26:require 'tree/Trees'
TokenSource.rb:2:require 'Recognizer'
atn/ATN.rb:1:require 'IntervalSet'
atn/ATN.rb:2:require 'RuleContext'
atn/ATN.rb:4:require 'Token'
atn/ATN.rb:5:require 'atn/ATNType'
atn/ATN.rb:6:require 'atn/ATNState' 
atn/ATN.rb:8:require 'java_symbols'
atn/ATN.rb:50:        require 'LL1Analyzer'
atn/ATNConfig.rb:13:require 'PredictionContext'
atn/ATNConfig.rb:14:require 'atn/ATNState'
atn/ATNConfig.rb:15:#require 'atn/LexerActionExecutor'
atn/ATNConfig.rb:16:#require 'atn/SemanticContext'
atn/ATNConfigSet.rb:5:require 'stringio'
atn/ATNConfigSet.rb:6:require 'PredictionContext'
atn/ATNConfigSet.rb:7:require 'atn/ATN'
atn/ATNConfigSet.rb:8:require 'atn/ATNConfig'
atn/ATNConfigSet.rb:9:#require 'atn/SemanticContext'
atn/ATNConfigSet.rb:10:require 'error'
atn/ATNConfigSet.rb:12:require 'forwardable'
atn/ATNDeserializer.rb:2:require 'stringio'
atn/ATNDeserializer.rb:3:require 'Token'
atn/ATNDeserializer.rb:4:require 'atn/ATN'
atn/ATNDeserializer.rb:5:require 'atn/ATNType'
atn/ATNDeserializer.rb:6:require 'atn/ATNState'
atn/ATNDeserializer.rb:7:require 'atn/Transition'
atn/ATNDeserializer.rb:8:require 'atn/LexerAction'
atn/ATNDeserializer.rb:9:require 'atn/ATNDeserializationOptions'
atn/ATNDeserializer.rb:11:require 'uuid'
atn/ATNSimulator.rb:6:require 'PredictionContext'
atn/ATNSimulator.rb:7:require 'atn/ATN'
atn/ATNSimulator.rb:8:require 'atn/ATNConfigSet'
atn/ATNSimulator.rb:9:require 'dfa/DFAState'
atn/ATNSimulator.rb:31:    #  For the Java grammar on java.*, it dropped the memory requirements
atn/LexerATNSimulator.rb:16:require 'Lexer'
atn/LexerATNSimulator.rb:17:require 'PredictionContext'
atn/LexerATNSimulator.rb:18:require 'InputStream'
atn/LexerATNSimulator.rb:19:require 'Token'
atn/LexerATNSimulator.rb:20:require 'atn/ATN'
atn/LexerATNSimulator.rb:21:require 'atn/ATNConfig'
atn/LexerATNSimulator.rb:22:require 'atn/ATNSimulator'
atn/LexerATNSimulator.rb:23:require 'atn/ATNConfigSet'
atn/LexerATNSimulator.rb:24:require 'atn/ATNState'
atn/LexerATNSimulator.rb:25:require 'atn/LexerActionExecutor'
atn/LexerATNSimulator.rb:26:require 'atn/Transition'
atn/LexerATNSimulator.rb:27:require 'dfa/DFAState'
atn/LexerATNSimulator.rb:28:require 'error'
atn/LexerATNSimulator.rb:30:require 'java_symbols'
atn/LexerAction.rb:4:require 'java_symbols'
atn/LexerAction.rb:273:# <p>This action is not serialized as part of the ATN, and is only required for
atn/LexerAction.rb:283:    # <p>Note: This class is only required for lexer actions for which
atn/LexerActionExecutor.rb:8:require 'InputStream'
atn/LexerActionExecutor.rb:10:require 'atn/LexerAction' 
atn/LexerActionExecutor.rb:112:        requiresSeek = false
atn/LexerActionExecutor.rb:120:                    requiresSeek = (startIndex + offset) != stopIndex
atn/LexerActionExecutor.rb:123:                    requiresSeek = false
atn/LexerActionExecutor.rb:128:            input.seek(stopIndex) if requiresSeek
atn/ParserATNSimulator.rb:49:# than interpreting and much more complicated. Also required a huge amount of
atn/ParserATNSimulator.rb:225:# both SLL and LL parsing. Erroneous input will therefore require 2 passes over
atn/ParserATNSimulator.rb:228:require 'dfa/DFA'
atn/ParserATNSimulator.rb:229:require 'PredictionContext'
atn/ParserATNSimulator.rb:230:require 'TokenStream'
atn/ParserATNSimulator.rb:231:require 'Parser'
atn/ParserATNSimulator.rb:232:require 'ParserRuleContext'
atn/ParserATNSimulator.rb:233:require 'RuleContext'
atn/ParserATNSimulator.rb:234:require 'Token'
atn/ParserATNSimulator.rb:235:require 'atn/ATN'
atn/ParserATNSimulator.rb:236:require 'atn/ATNConfig'
atn/ParserATNSimulator.rb:237:require 'atn/ATNConfigSet'
atn/ParserATNSimulator.rb:238:require 'atn/ATNSimulator'
atn/ParserATNSimulator.rb:239:require 'atn/ATNState'
atn/ParserATNSimulator.rb:240:require 'atn/PredictionMode'
atn/ParserATNSimulator.rb:241:require 'atn/SemanticContext'
atn/ParserATNSimulator.rb:242:require 'atn/Transition'
atn/ParserATNSimulator.rb:243:require 'dfa/DFAState'
atn/ParserATNSimulator.rb:244:require 'error'
atn/ParserATNSimulator.rb:442:            if cD.requiresFullContext and self.predictionMode != PredictionMode.SLL
atn/ParserATNSimulator.rb:560:            cD.requiresFullContext = true
atn/ParserATNSimulator.rb:716:        # For full-context reach operations, separate handling is required to
atn/ParserATNSimulator.rb:799:            # required.
atn/PredictionMode.rb:11:require 'atn/ATN'
atn/PredictionMode.rb:12:require 'atn/ATNConfig'
atn/PredictionMode.rb:13:require 'atn/ATNConfigSet'
atn/PredictionMode.rb:14:require 'atn/ATNState'
atn/PredictionMode.rb:15:require 'atn/SemanticContext'
atn/PredictionMode.rb:16:require 'java_symbols'
atn/PredictionMode.rb:34:    # that the particular combination of grammar and input requires the more
atn/PredictionMode.rb:287:    # <p>No special consideration for semantic predicates is required because
atn/SemanticContext.rb:11:require 'Recognizer'
atn/SemanticContext.rb:12:require 'RuleContext'
atn/Transition.rb:15:require 'IntervalSet'
atn/Transition.rb:16:require 'Token'
atn/Transition.rb:18:require 'atn/SemanticContext'
atn/Transition.rb:20:require 'java_symbols'
base.rb:1:require 'Token' 
base.rb:2:require 'FileStream'
base.rb:3:require 'TokenStream' 
base.rb:4:require 'BufferedTokenStream'
base.rb:5:require 'CommonTokenStream'
base.rb:6:require 'Lexer'
base.rb:7:require 'Parser'
base.rb:8:require 'dfa/DFA'
base.rb:9:require 'atn/ATN'
base.rb:10:require 'atn/ATNDeserializer'
base.rb:11:require 'atn/LexerATNSimulator'
base.rb:12:require 'atn/ParserATNSimulator' 
base.rb:13:require 'atn/PredictionMode'
base.rb:14:require 'PredictionContext'
base.rb:15:require 'ParserRuleContext'
base.rb:16:require 'tree/Tree' # import ParseTreeListener, ParseTreeVisitor, ParseTreeWalker, TerminalNode, ErrorNode, RuleNode
base.rb:17:require 'error'    #  Errors import RecognitionException, IllegalStateException, NoViableAltException
base.rb:18:require 'error/ErrorStrategy' # import BailErrorStrategy
base.rb:19:require 'error/DiagnosticErrorListener' # import DiagnosticErrorListener
base.rb:21:require 'java_symbols'
dfa/DFA.rb:9:require 'dfa/DFASerializer'
dfa/DFA.rb:102:                precedenceState.requiresFullContext = false
dfa/DFASerializer.rb:3:require 'stringio'
dfa/DFASerializer.rb:58:        s_requireContext = nil
dfa/DFASerializer.rb:59:        s_requireContext = "^" if s.requiresFullContext 
dfa/DFASerializer.rb:60:        baseStateStr = "s#{s.stateNumber}#{s_requireContext}"
dfa/DFAState.rb:2:require 'stringio'
dfa/DFAState.rb:45:    attr_accessor :lexerActionExecutor, :requiresFullContext, :predicates 
dfa/DFAState.rb:55:        #  {@link #requiresFullContext}.
dfa/DFAState.rb:62:        self.requiresFullContext = false
dfa/DFAState.rb:65:        #  {@link #requiresFullContext} is {@code false} since full context prediction evaluates predicates
dfa/DFAState.rb:69:        #  <p>We only use these for non-{@link #requiresFullContext} but conflicting states. That
error/DiagnosticErrorListener.rb:52:require 'stringio'
error/DiagnosticErrorListener.rb:53:require 'set'
error/DiagnosticErrorListener.rb:56:require 'error/ErrorListener'
error/ErrorStrategy.rb:32:# require 'IntervalSet' #from antlr4.IntervalSet import IntervalSet
error/ErrorStrategy.rb:34:#require 'antlr4/Token' #from antlr4.Token import Token
error/ErrorStrategy.rb:35:#require 'atn.ATNState' #from antlr4.atn.ATNState import ATNState
error/ErrorStrategy.rb:323:    # This method is called to report a syntax error which requires the removal
error/ErrorStrategy.rb:350:    # This method is called to report a syntax error which requires the
error/ErrorStrategy.rb:640:    #  return normally.  Rule b would not find the required '^' though.
xpath/XPath.rb:59:require 'TokenStream'
xpath/XPath.rb:60:require 'CommonTokenStream'
xpath/XPath.rb:61:require 'java_symbols'
