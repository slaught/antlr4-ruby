
RUBY=rbx 
RUBY_SYNTAX=$(RUBY) -c


all: test
	echo "done"

build:
	javac -d ~/lib tool/src/org/antlr/v4/codegen/RubyTarget.java
	cp -r tool/resources/ ~/lib/

test: build gen_test syntax_check run_test

gen_test:
	(cd t; java org.antlr.v4.Tool PjmInvoice.g4)

syntax_check: 
	$(RUBY_SYNTAX) t/PjmInvoiceLexer.rb   
	$(RUBY_SYNTAX) t/PjmInvoiceListener.rb 
	$(RUBY_SYNTAX) t/PjmInvoiceParser.rb

run_test:
	$(RUBY) -It t/PjmInvoiceLexer.rb   
	$(RUBY) -It t/PjmInvoiceListener.rb 
	$(RUBY) -It t/PjmInvoiceParser.rb

add:
	git add tool/resources/org/antlr/v4/tool/templates/codegen/Ruby/Ruby.stg
	git add tool/src/org/antlr/v4/codegen/RubyTarget.java

