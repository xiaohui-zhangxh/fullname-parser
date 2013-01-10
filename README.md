fullname_parser
===============

There are two ways to use this function:

require 'fullname/parser'
Fullname::Parser.parse_fullname("Xiaohui Zhang")

=> {:last=>"Zhang", :middle=>nil, :first=>"Xiaohui", :prefix=>nil, :suffix=>nil}

or

require 'fullname/parser'
include Fullname::Parser
parse_fullname("Xiaohui Zhang")

=> {:last=>"Zhang", :middle=>nil, :first=>"Xiaohui", :prefix=>nil, :suffix=>nil}

