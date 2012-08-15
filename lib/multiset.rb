#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

VERSION = "0.4.0"

#Rubyによる多重集合（マルチセット）・多重連想配列（マルチマップ）の実装です。
#
#Ruby implementation of multiset and multimap.

require 'multiset/libmultiset'
require 'multiset/libmultimap'

#--
# Sample
#++
if __FILE__ == $0
	puts 'Creating multisets'
	a = {1=>5, 4=>2, 6=>0}.to_multiset
	b = Multiset[1,1,4,4,6,6]
	p a
	p b
	
	puts 'Operations for multisets'
	p a + b
	p a - b
	p a & b
	p a | b
	
	puts 'Modifying multisets'
	p a.reject!{ |item| item == 3 }
	p a
	p a.reject!{ |item| item == 4 }
	p a
	a.add(3)
	a.add(4, 10)
	a << 1
	p a
  
	puts 'Flattening multisets'
	a = Multiset[6,6,3,4,Multiset[5,8],Multiset[6,Multiset[3,8],8],8]
	p a
	p a.flatten!
	p a.flatten!
end
