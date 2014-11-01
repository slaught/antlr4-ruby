
require 'test/unit'

$: << 'lib'
require 'antlr4'
require 'tree/Tree'
require 'Token'

require 'ostruct'

class SampleNodeImpl
  include NodeImpl
end

class TreeTest < Test::Unit::TestCase

  def setup()
  end
  def teardown 
  end

  def test_create
    [Tree, SyntaxTree, ParseTree, RuleNode,
        TerminalNode, ErrorNode,
        ParseTreeListener,  ParseTreeVisitor].each { |cls|
      assert_not_nil cls.new 
      assert  cls.new.kind_of? cls
    }
  end

  def test_terminal_node
    assert_not_nil TerminalNode.new
  end
  def test_error_node
    assert_not_nil ErrorNode.new 
  end

  def test_listener 
    t = ParseTreeListener.new
    m = t.methods - Object.new.methods
    assert m.length == 4
    assert_nil t.visitTerminal(nil)
    assert_nil t.visitErrorNode(nil)
    assert_nil t.enterEveryRule(nil)
    assert_nil t.exitEveryRule(nil)
  end


  def test_node_impl
      n = SampleNodeImpl.new(:symbol)
      n = node_impl_verify(SampleNodeImpl)
      assert n.kind_of?(NodeImpl), "not kind_of NodeImpl"
  end
      
  def node_impl_verify(klass)
      n = klass.new(:symbol)
      assert_not_nil n           ,"initialize fails"
      assert_nil     n.parentCtx , "init value1 fails"
      assert_not_nil     n.symbol , "init value2 fails"
      assert         :symbol == n.symbol , "Symbol is not set"


      assert :symbol == n.getSymbol(),  "getSymbol does not work" 
      assert :symbol == n.getPayload(), "getSymbol does not work" 
      assert n.symbol = :new_symbol,    "symbol= does not exist"
      assert :new_symbol == n.symbol,   "symbol= does not work"

      assert n.parentCtx = :new_symbol,   "parentCtx= does not exist"
      assert :new_symbol == n.parentCtx,  "parentCtx= does not work"
      assert n.parentCtx == n.getParent,  "getParent does not work"

      assert_nil n.getChild(nil),         "getChild() does not work"
      assert     n.getChildCount() == 0 , "getChildCount does not work"
      n 
  end
  def test_node_impl_with_token
      token = CommonToken.new([nil,TokenStream.new])
      token.text = "text" 
      assert_not_nil token , "CommonToken failed to init"
      n = SampleNodeImpl.new(token)
      assert_not_nil n, "failed to create samplenodeimpl with token"
      assert_not_nil n.getSourceInterval() , "getSourceInterval failed"
      assert_not_nil n.getText() , "getText failed"
      assert_not_nil n.to_s , "to_s failed"
      assert n.to_s == "text" , "to_s value failed"
  end
  def test_node_impl_symbol
      tok = OpenStruct.new(:type=> 100, :text => "text")
      n = SampleNodeImpl.new(tok)
      assert n
      assert n.to_s == "text"
      assert n.getText == "text"
      tok = OpenStruct.new(:type=> Token::EOF, :text => "text")
      n = SampleNodeImpl.new(tok)
      assert n
      assert n.to_s == "<EOF>"
      assert n.getText == "text"
  end
  def test_node_impl_nil_symbol 
      n = SampleNodeImpl.new(nil)
      assert n
      assert_nil n.symbol , "symbol is not nil"
      assert n.getSourceInterval() , "getSourceInterval failed"
      assert n.getSourceInterval() == Antlr4::INVALID_INTERVAL , "getSourceInterval failed"
  end
#    def getText()
#        return self.symbol.text
#    end
#
#    def to_s
##        if self.symbol.type == Token.EOF then
#            "<EOF>"
#        else
#            self.symbol.text
#        end
#    end
#  end
  class SampleParseTreeVisitor <  ParseTreeVisitor
      def visitTerminal(a)
            true
      end
  end
  def test_node_impl_accept
      n = SampleNodeImpl.new(:symbol)
      assert_not_nil n , "init failed to create NodeImpl"
      assert n.accept(SampleParseTreeVisitor.new) , "NodeImpl::accept() fail"
  end
  def test_terminal_node_impl
    t = node_impl_verify(TerminalNodeImpl)
    assert t.kind_of?(TerminalNode), "Not a kind_of? TerminalNode"
  end
  def test_error_node_impl
      n = node_impl_verify(ErrorNodeImpl)
      assert n.kind_of?(TerminalNode), "Not a kind_of? TerminalNode"
      assert n.kind_of?(ErrorNode), "Not a kind_of? ErrorNode"
      assert_nil n.accept(ParseTreeVisitor.new), "accept(ParseTreeVisitor)"
  end
#

end
