#  This is an InputStream that is loaded from a file all at once
#  when you construct the object.
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
