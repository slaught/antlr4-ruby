# [The "BSD license"]
#  Copyright (c) 2012 Terence Parr
#  Copyright (c) 2012 Sam Harwell
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#  Sometimes we need to map a key to a value but key is two pieces of data.
#  This nested hash table saves creating a single key each time we access
#  map; avoids mem creation.
class DoubleKeyMap 

  def initialize
      #	Map<Key1, Map<Key2, Value>> data = new LinkedHashMap<Key1, Map<Key2, Value>>();
      @data = Hash.new
  end

  def put(k1, k2, v) 
		data2 = @data.get(k1)
		prev = nil
		if data2.nil? then
			data2 = Hash.new
			@data[k1] = data2 
		else 
			prev = data2[k2]
		end
		data2[k2] = v
		return prev;
	end

	def get(k1, k2=nil) 
		data2 = @data[k1]
		return nil if data2.nil? 
    if k2.nil? then
      data2
    else
  		data2[k2]
    end
	end

#	/** Get all values associated with primary key */
	def values(k1) 
		data2 = @data[k1]
		return nil if data2.nil? 
		data2.values();
	end

#	/** get all secondary keys associated with a primary key */
	def keySet(k1=nil) 
    #	/** get all primary keys 
    return @data.keys if k1.nil?
		data2 = @data[k1]
		return nil if data2.nil? 
		data2.keys
	end
end
