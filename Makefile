
RUBY=rbx 
RUBY_SYNTAX=$(RUBY) -c

BUILD_DIR=BUILD

$(BUILD_DIR): 
	mkdir $(BUILD_DIR)
  
antlr4-ruby.jar: $(BUILD_DIR)
	javac -d $(BUILD_DIR) tool/src/org/antlr/v4/codegen/RubyTarget.java
	cp -r tool/resources/ $(BUILD_DIR)
	jar cf $@  -C $(BUILD_DIR) org


all: test
	echo "done"

build:
	javac -d ~/lib tool/src/org/antlr/v4/codegen/RubyTarget.java
	cp -r tool/resources/ ~/lib/

test: build gen_test syntax_check run_test

gen_test:
	(cd t; java org.antlr.v4.Tool -Dlanguage=Ruby PjmInvoice.g4)

syntax_check: 
	$(RUBY_SYNTAX) t/PjmInvoiceLexer.rb   
	$(RUBY_SYNTAX) t/PjmInvoiceListener.rb 
	$(RUBY_SYNTAX) t/PjmInvoiceParser.rb

run_test:
	$(RUBY) -Ilib:t t/PjmInvoiceLexer.rb   
	$(RUBY) -Ilib:t t/PjmInvoiceListener.rb 
	$(RUBY) -Ilib:t t/PjmInvoiceParser.rb

add:
	git add tool/resources/org/antlr/v4/tool/templates/codegen/Ruby/Ruby.stg
	git add tool/src/org/antlr/v4/codegen/RubyTarget.java

test1:
	rbx -It -Ilib RubyTest.rb pjm_msrs_Week_Bill_L_2014-07-26.pjmcsv

test2: 
	rbx -It:lib t1.rb

test3:
	rbx -It -Ilib RubyTest.rb test1 pjm_msrs_Week_Bill_L_2014-07-26.pjmcsv





