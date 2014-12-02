This is the Ruby runtime and target for Antlr4. 

This is based on the Python3 & Java runtime & targets.
It includes the Java code for antlr to use *language = Ruby ;* and
the runtime gem for the ruby code to run. There is a simplistic 
_bin/antlr-testrig_ for quickly loading a Lexer/Parser pair and
running them on an input file. 

Usage
-----
To use the Ruby language codegen for Antlrv4 do the following.

1. Create the jar file.
    ```% make antlr4-ruby.jar ```

2. Put the jar file in your java class path 

3. Use either the _options_ section  or the _-Dlanguage=_ switch

```
  options {  language = Ruby ; }
```

```
java org.antlr.v4.Tool -Dlanguage=Ruby input.g4
```

Build gem for use by Ruby code. It is placed in _pkg_.
```
rake build 
```

You can then install with Bundler or Rubygems directly.


Missing Features
----------------
* Ruby runtime is not in a proper module and library setup
* The Ruby test for integration with antlr4 are missing
* Proper attribution of all code


### Fixed Bugs ###
* Ruby MRI encoding causes fails with some generated ATNs.
 This was fixed by using \x instead of \u for ATN encoding.

