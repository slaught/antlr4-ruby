#  This is an InputStream that is loaded from a file all at once
#  when you construct the object.

#import codecs
#import unittest
#from antlr4.InputStream import InputStream
require 'InputStream'


class FileStream < InputStream

    def initialize(fileName, encoding=nil)
        # read binary to avoid line ending conversion
        bytes = nil
        File.open(fileName, 'rb') do |file|
            bytes = file.read()
        end
        super(bytes)
        @name = fileName
    end
end

#class TestFileStream(unittest.TestCase):
#
#    def testStream(self):
#        stream = FileStream("FileStream.py")
#        self.assertTrue(stream.size>0)
