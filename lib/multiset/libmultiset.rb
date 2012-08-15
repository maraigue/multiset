#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "enumerator"

#==概要(Basic information)
#
# Rubyによる多重集合（マルチセット）の実装です。
# 通常の集合（Rubyでは"set"ライブラリ）と異なり、多重集合は
# 同一の要素を複数格納することができます。
#
# メソッド名は基本的にSetクラスに合わせてあります。またSetクラスが持つ
# メソッドの大部分を実装していますが、いくつか未実装なものもあります。
#
# Ruby implementation of multiset.
# Unlike ordinary set(see Ruby documentation for "set" library),
# multiset can contain two or more same items.
#
# Most methods' names are same as those of Set class, and all other than
# a few methods in Set class is implemented on Multiset class.
#
# * <code>Set[:a,:b,:c,:b,:b,:c] => #<Set: {:b, :c, :a}></code>
# * <code>Multiset[:a,:b,:c,:b,:b,:c] => #<Multiset:<tt>#</tt>3 :b, <tt>#</tt>2 :c, <tt>#</tt>1 :a></code>

class Multiset
	include Enumerable
	
	#--
  # ============================================================
	# コンストラクタ
  # ============================================================
	#++
	
	# <code>list</code>に含まれる要素からなる多重集合を生成します。
	# <code>list</code>を省略した場合、空の多重集合を生成します。
	#
	# <code>list</code>には<code>Enumerable</code>であるオブジェクトのみ
	# 指定できます。そうでない場合、例外<code>ArgumentError</code>が
	# 発生します。
	#
	# Generates a multiset from items in <code>list</code>.
	# If <code>list</code> is omitted, returns empty multiset.
	#
	# <code>list</code> must be <code>Enumerable</code>. If not,
	# <code>ArgumentError</code> is raised.
	def initialize(list = nil)
		@entries = {}
		if list.kind_of?(Enumerable)
			list.each{ |item| add item }
		elsif list != nil
			raise ArgumentError, "Item list must include 'Enumerable' module"
		end
	end
	
	# <code>list</code>に含まれる要素からなる多重集合を生成します。
	# <code>new</code>を用いる場合と異なり、引数の1つ1つが多重集合の要素になります。
	#
	# 主に多重集合のリテラルを生成するのに用います。
	#
	# Generates a multiset from items in <code>list</code>.
	# Unlike using <code>new</code>, each argument is one item in generated multiset.
	#
	# This method is mainly used when you generate literal of multiset.
	def Multiset.[](*list)
		Multiset.new(list)
	end
	
	# <code>object</code>を多重集合に変換し生成します。
	# * <code>object</code>がMultisetのインスタンスである場合、
	#   その複製を返します。
	# * <code>object</code>がMultisetのインスタンスでなく、
	#   かつ<code>each_pair</code>メソッドを持っている場合、
	#   <code>each_pair</code>から渡される2つの引数について、前者を要素、
	#   後者をその個数とした多重集合を生成します。Hash#to_multisetも
	#   ご覧下さい。
	# * <code>object</code>が<code>each_pair</code>メソッドを持っておらず、
	#   かつ<code>Enumerable</code>である場合は、Multiset#newと同じ結果です。
	# * それ以外の場合は、例外<code>ArgumentError</code>が発生します。
	# 
	# Generates a multiset converting <code>object</code>.
	# * If <code>object</code> is an instance of Multiset, returns
	#   duplicated <code>object</code>.
	# * If <code>object</code> is not an instance of Multiset and has
	#   the method <code>each_pair</code>,
	#   for each pair of two arguments from <code>each_pair</code>,
	#   first argument becomes item in multiset and second argument
	#   becomes its number. See also Hash#to_multiset .
	# * If <code>object</code> does not have the method <code>each_pair</code>
	#   and <code>object</code> includes <code>Enumerable</code>, this method
	#   results equal to Multiset#new .
	# * Otherwise, <code>ArgumentError</code> is raised.
	def Multiset.parse(object)
		if object.kind_of?(String)
			raise ArgumentError, "Multiset.parse can not parse strings. If you would like to store string lines to a multiset, use Multiset.from_lines(string)."
		end
    
		if object.instance_of?(Multiset)
			ret = object.dup
		else
			ret = Multiset.new
			if defined? object.each_pair
				object.each_pair{ |item, count| ret.add item, count }
			elsif object.kind_of?(Enumerable)
				object.each{ |item| ret.add item }
			else
				raise ArgumentError, "Source of Multiset must have 'each_pair' method or include 'Enumerable' module"
			end
		end
		ret
  end
	
	# 文字列を行単位で区切ってMultisetにします。
  # 
  # Generates a Multiset from string, separated by lines.
	def Multiset.from_lines(str)
    Multiset.new(str.enum_for(:each_line))
	end
	
  # 文字列が渡された場合は、Multiset.from_linesと同じ挙動。
  # それ以外の場合は、Multiset.parseと同じ挙動。
  # 
  # If a string is given, it works as Multiset.from_lines,
  # otherwise as Multiset.parse.
	def Multiset.parse_force(object)
		if object.kind_of?(String)
			Multiset.from_lines(object)
    else
      Multiset.parse(object)
		end
	end
	
	# <code>self</code>の複製を生成して返します。
	#
	# Returns duplicated <code>self</code>.
	def dup
		@entries.to_multiset
	end
	
	# <code>self</code>を<code>Hash</code>に変換して返します。
	# 生成されるハッシュの構造については、Hash#to_multisetをご覧下さい。
	#
	# Converts <code>self</code> to a <code>Hash</code>.
	# See Hash#to_multiset about format of generated hash.
	def to_hash
		@entries.dup
	end
	
	#--
  # ============================================================
	# 別の型への変換、基本的な関数など
  # ============================================================
	#++
	
	# <code>self</code>を通常の集合（Ruby標準添付の<code>Set</code>）に
	# 変換したものを返します。
	#
	# このメソッドを呼び出すと、<code>require "set"</code>が行われます。
	#
	# なおSetをMultisetに変換するには、<code>Multiset.new(instance_of_set)</code>で
	# 可能です。
	#
	# Converts <code>self</code> to ordinary set
	# (The <code>Set</code> class attached to Ruby by default).
	#
	# <code>require "set"</code> is performed when this method is called.
	#
	# To convert Set to Multiset, use <code>Multiset.new(instance_of_set)</code>.
	def to_set
		require "set"
		Set.new(@entries.keys)
	end
	
	# <code>self</code>を配列に変換して返します。
	#
	# Converts <code>self</code> to an array.
	def to_a
		ret = []
		@entries.each_pair do |item, count|
			ret.concat Array.new(count, item)
		end
		ret
	end
	
	def hash # :nodoc:
		val = 0
		@entries.each_pair do |item, count|
			val += item.hash * count
		end
		val
	end
	
	def eql?(other) # :nodoc:
		if self.hash == other.hash
			self == other
		else
			false
		end
	end
	
	#--
  # ============================================================
	# 基本操作（他のメソッドを定義するのに頻出するメソッドなど）
  # ============================================================
	#++
	
	# <code>self</code>の内容を<code>other</code>のものに置き換えます。
	# <code>self</code>を返します。
	#
	# Replaces <code>self</code> by <code>other</code>.
	# Returns <code>self</code>.
	def replace(other)
		@entries.clear
		other.each_pair do |item, count|
			self.renew_count(item, count)
		end
		self
	end
	
	# <code>self</code>に含まれている要素数を返します。
	#
	# Returns number of all items in <code>self</code>.
	def size
		@entries.inject(0){ |sum, item| sum += item[1] }
	end
	alias length size
	
	# <code>self</code>に要素がないかどうかを返します。
	#
	# Returns whether <code>self</code> has no item.
	def empty?
		@entries.empty?
	end
	
	# <code>self</code>に含まれている要素（重複は除く）からなる配列を返します。
	#
	# Returns an array with all items in <code>self</code>, without duplication.
	def items
		@entries.keys
	end
	
	# <code>self</code>の要素をすべて削除します。
	# <code>self</code>を返します。
	#
	# Deletes all items in <code>self</code>.
	# Returns <code>self</code>.
	def clear
		@entries.clear
		self
	end
	
	# <code>item</code>が<code>self</code>中に含まれているかを返します。
	#
	# Returns whether <code>self</code> has <code>item</code>.
	def include?(item)
		@entries.has_key?(item)
	end
	alias member? include?
	
	# <code>self</code>の全要素を（重複を許して）並べた文字列を返します。
	# 要素間の区切りは<code>delim</code>の値を用い、
	# 各要素の表示形式は与えられたブロックの返り値（なければObject#inspect）を用います。
	#
	# Lists all items with duplication in <code>self</code>.
	# Items are deliminated with <code>delim</code>, and items are
	# converted to string in the given block.
	# If block is omitted, Object#inspect is used.
	def listing(delim = "\n")
		buf = ''
		init = true
		self.each do |item|
			if init
				init = false
			else
				buf += delim
			end
			buf += block_given? ? yield(item).to_s : item.inspect
		end
		buf
	end
	
	# <code>self</code>の要素と要素数の組を並べた文字列を返します。
	# 要素間の区切りは<code>delim</code>の値を用い、
	# 各要素の表示形式は与えられたブロックの返り値（なければObject#inspect）を用います。
	#
	# Lists all items without duplication and its number in <code>self</code>.
	# Items are deliminated with <code>delim</code>, and items are
	# converted to string in the given block.
	# If block is omitted, Object#inspect is used.
	def to_s(delim = "\n")
		buf = ''
		init = true
		@entries.each_pair do |item, count|
			if init
				init = false
			else
				buf += delim
			end
			item_tmp = block_given? ? yield(item) : item.inspect
			buf += "\##{count} #{item_tmp}"
		end
		buf
	end
	
	def inspect # :nodoc:
		buf = "#<Multiset:"
		buf += self.to_s(', ')
		buf += '>'
		buf
	end
  
	#--
  # ============================================================
	# 要素数の更新
  # ============================================================
	#++
  
	# <code>self</code>中に含まれる<code>item</code>の個数を返します。
  # 引数を指定しない場合は、Multiset#sizeと同じです。
  # ブロックを指定することもでき、その場合は（重複しない）各要素をブロックに与え、
  # 条件を満たした（結果が真であった）要素がMultiset内にいくつ入っているかを数えます。
	#
	# Returns number of <code>item</code>s in <code>self</code>.
  # If the <code>item</code> is omitted, the value is same as Multiset#size.
  # If a block is given, each element (without duplication) is given to
  # the block, and returns the number of elements (including duplication)
  # that returns true in the block.
  # 
  # :call-seq:
  #   count(item)
  #   count{ |item| ... }
	def count(*item_list)
    if block_given?
      unless item_list.empty?
        raise ArgumentError, "Both item and block cannot be given"
      end
      
      result = 0
      @entries.each_pair do |i, c|
        result += c if yield(i)
      end
      result
    else
      case item_list.size
      when 0
        self.size
      when 1
        @entries.has_key?(item_list.first) ? @entries[item_list.first] : 0
      else
        raise ArgumentError, "Only one item can be given"
      end
    end
	end
	
	# <code>self</code>に含まれる<code>item</code>の個数を<code>number</code>個にします。
	# <code>number</code>が負の数であった場合は、<code>number = 0</code>とみなします。
	# 成功した場合は<code>self</code>を、失敗した場合は<code>nil</code>を返します。
	#
	# Sets number of <code>item</code> to <code>number</code> in <code>self</code>.
	# If <code>number</code> is negative, treats as <code>number = 0</code>.
	# Returns <code>self</code> if succeeded, <code>nil</code> otherwise.
	def renew_count(item, number)
		return nil if number == nil
		n = number.to_i
		if n > 0
			@entries[item] = n
		else
			@entries.delete(item)
		end
		self
	end
	
	# <code>self</code>に、<code>addcount</code>個の<code>item</code>を追加します。
	# 成功した場合は<code>self</code>を、失敗した場合は<code>nil</code>を返します。
	#
	# Adds <code>addcount</code> number of <code>item</code>s to <code>self</code>.
	# Returns <code>self</code> if succeeded, or <code>nil</code> if failed.
	def add(item, addcount = 1)
		return nil if addcount == nil
		a = addcount.to_i
		return nil if a <= 0
		self.renew_count(item, self.count(item) + a)
	end
	alias << add
	
	# <code>self</code>から、<code>delcount</code>個の<code>item</code>を削除します。
	# 成功した場合は<code>self</code>を、失敗した場合は<code>nil</code>を返します。
	#
	# Deletes <code>delcount</code> number of <code>item</code>s
	# from <code>self</code>.
	# Returns <code>self</code> if succeeded, <code>nil</code> otherwise.
	def delete(item, delcount = 1)
		return nil if delcount == nil || !self.include?(item)
		d = delcount.to_i
		return nil if d <= 0
		self.renew_count(item, self.count(item) - d)
	end
	
	# <code>self</code>に含まれる<code>item</code>をすべて削除します。
	# <code>self</code>を返します。
	#
	# Deletes all <code>item</code>s in <code>self</code>.
	# Returns <code>self</code>.
	def delete_all(item)
		@entries.delete(item)
		self
	end
	
	#--
  # ============================================================
	# 包含関係の比較
  # ============================================================
	#++
	
	# <code>self</code>と<code>other</code>が持つすべての要素（重複なし）について
	# 繰り返し、ブロックの返り値が偽であるものが存在すればその時点でfalseを返します。
	# すべての要素について真であればtrueを返します。
	#
	# このメソッドはsuperset?、subset?、== のために定義されています。
	#
	# Iterates for each item in <code>self</code> and <code>other</code>,
	# without duplication. If the given block returns false, then iteration
	# immediately ends and returns false.
	# Returns true if the given block returns true for all of iteration.
	# 
	# This method is defined for methods superset?, subset?, ==.
	def compare_set_with(other) # :nodoc: :yields: number_in_self, number_in_other
		(self.items | other.items).each do |item|
			return false unless yield(self.count(item), other.count(item))
		end
		true
	end
	
	# <code>self</code>が<code>other</code>を含んでいるかどうかを返します。
	# 
	# Returns whether <code>self</code> is a superset of <code>other</code>.
	def superset?(other)
		unless other.instance_of?(Multiset)
			raise ArgumentError, "Argument must be a Multiset"
		end
		compare_set_with(other){ |s, o| s >= o }
	end
	
	# <code>self</code>が<code>other</code>を真に含んでいるかどうかを返します。
	# 「真に」とは、両者が一致する場合は含めないことを示します。
	# 
	# Returns whether <code>self</code> is a proper superset of <code>other</code>.
	def proper_superset?(other)
		unless other.instance_of?(Multiset)
			raise ArgumentError, "Argument must be a Multiset"
		end
		self.superset?(other) && self != other
	end
	
	# <code>self</code>が<code>other</code>に含まれているかどうかを返します。
	# 
	# Returns whether <code>self</code> is a subset of <code>other</code>.
	def subset?(other)
		unless other.instance_of?(Multiset)
			raise ArgumentError, "Argument must be a Multiset"
		end
		compare_set_with(other){ |s, o| s <= o }
	end
	
	# <code>self</code>が<code>other</code>に真に含まれているかどうかを返します。
	# 「真に」とは、両者が一致する場合は含めないことを示します。
	# 
	# Returns whether <code>self</code> is a proper subset of <code>other</code>.
	def proper_subset?(other)
		unless other.instance_of?(Multiset)
			raise ArgumentError, "Argument must be a Multiset"
		end
		self.subset?(other) && self != other
	end
	
	# <code>self</code>が<code>other</code>と等しいかどうかを返します。
	#
	# Returns whether <code>self</code> is equal to <code>other</code>.
	def ==(other)
		return false unless other.instance_of?(Multiset)
		compare_set_with(other){ |s, o| s == o }
	end
	
	#--
  # ============================================================
	# その他、2つのMultisetについての処理
  # ============================================================
	#++
	
	# <code>self</code>と<code>other</code>の要素を合わせた多重集合を返します。
	#
	# Returns merged multiset of <code>self</code> and <code>other</code>.
	def merge(other)
		ret = self.dup
		other.each_pair do |item, count|
			ret.add(item, count)
		end
		ret
	end
	alias + merge
	
	# <code>self</code>に<code>other</code>の要素を追加します。
	# <code>self</code>を返します。
	#
	# Merges <code>other</code> to <code>self</code>.
	# Returns <code>self</code>.
	def merge!(other)
		other.each_pair do |item, count|
			self.add(item, count)
		end
		self
	end
	
	# <code>self</code>から<code>other</code>の要素を取り除いた多重集合を返します。
	#
	# Returns multiset such that items in <code>other</code> are removed from <code>self</code>.
	def subtract(other)
		ret = self.dup
		other.each_pair do |item, count|
			ret.delete(item, count)
		end
		ret
	end
	alias - subtract
	
	# <code>self</code>から<code>other</code>の要素を削除します。
	# <code>self</code>を返します。
	#
	# Removes items in <code>other</code> from <code>self</code>.
	# Returns <code>self</code>.
	def subtract!(other)
		other.each_pair do |item, count|
			self.delete(item, count)
		end
		self
	end
	
	# <code>self</code>と<code>other</code>の積集合からなる多重集合を返します。
	#
	# Returns intersection of <code>self</code> and <code>other</code>.
	def &(other)
		ret = Multiset.new
		(self.items & other.items).each do |item|
			ret.renew_count(item, [self.count(item), other.count(item)].min)
		end
		ret
	end
	
	# <code>self</code>と<code>other</code>の和集合からなる多重集合を返します。
	#
	# Returns union of <code>self</code> and <code>other</code>.
	def |(other)
		ret = self.dup
		other.each_pair do |item, count|
			ret.renew_count(item, [self.count(item), count].max)
		end
		ret
	end
	
	#--
  # ============================================================
	# 1つのMultisetの各要素についての処理
  # ============================================================
	#++
	
	# <code>self</code>に含まれるすべての要素について繰り返します。
	# <code>self</code>を返します。
  # ブロックが与えられていない場合、Enumeratorを返します。
  # 
  # このメソッドは Enumerable#each の挙動に合わせ、同じ要素を何度もブロックに
  # 渡すため、効率が悪いです。Multiset#each_item, Multiset#each_pairの利用もご検討下さい。
  # 例えば「"a"が100個入ったMultiset」をeachで繰り返すと100回の処理が行われますが、
  # each_pairなら1回で済みます。
	# 
	# Iterates for each item in <code>self</code>.
	# Returns <code>self</code>.
  # An Enumerator will be returned if no block is given.
  # 
  # This method is ineffective since the same element in the Multiset
  # can be given to the block for many times, same as the behavior of Enumerable#each.
  # Please consider using Multiset#each_item or Multiset#each_pair: for example,
  # a Multiset with 100 times "a" will call the given block for 100 times for Multiset#each,
  # while only once for Multiset#each_pair.
	def each
		@entries.each_pair do |item, count|
			count.times{ yield item }
		end
		self
	end
	
	# <code>self</code>に含まれるすべての要素について、重複を許さずに繰り返します。
	# <code>self</code>を返します。
  # ブロックが与えられていない場合、Enumeratorを返します。
	#
	# Iterates for each item in <code>self</code>, without duplication.
	# Returns <code>self</code>.
  # An Enumerator will be returned if no block is given.
	def each_item(&block) # :yields: item
		@entries.each_key(&block)
		self
	end
	
	# <code>self</code>に含まれるすべての要素（重複なし）とその個数について繰り返します。
	# <code>self</code>を返します。
  # ブロックが与えられていない場合、Enumeratorを返します。
	#
	# Iterates for each pair of (non-duplicated) item and its number in <code>self</code>.
	# Returns <code>self</code>.
  # An Enumerator will be returned if no block is given.
	def each_with_count(&block) # :yields: item, count
		@entries.each_pair(&block)
		self
	end
  alias :each_pair :each_with_count
	
	# <code>self</code>の各要素（重複なし）をブロックに与え、返り値を集めたものからなる
	# 多重集合を生成します。
	# 
	# Gives all items in <code>self</code> (without duplication) to given block,
	# and generates a new multiset whose values are returned value from the block.
	def map # :yields: item
		ret = Multiset.new
		@entries.each_pair do |item, count|
			ret.add(yield(item), count)
		end
		ret
	end
	alias collect map
	
	# Multiset#mapと同様ですが、結果として生成される多重集合で<code>self</code>が
	# 置き換えられます。<code>self</code>を返します。
	# 
	# Same as Multiset#map, but replaces <code>self</code> by resulting multiset.
	# Returns <code>self</code>.
	def map!(&block) # :yields: item
    self.replace(self.map(&block))
		self
	end
	alias collect! map!
	
	# <code>self</code>の要素（重複なし）とその個数の組をブロックに与えます。
	# ブロックから2要素の配列を受け取り、前者を要素、後者をその個数とした
	# 多重集合を生成します。
	# 
	# Gives all pairs of (non-duplicate) items and their numbers in <code>self</code> to
	# given block. The block must return an array of two items.
	# Generates a new multiset whose values and numbers are the first and
	# second item of returned array, respectively.
	def map_with
		ret = Multiset.new
		@entries.each_pair do |item, count|
			val = yield(item, count)
			ret.add(val[0], val[1])
		end
		ret
	end
	alias collect_with map_with
	
	# Multiset#map_withと同様ですが、結果として生成される多重集合で
	# <code>self</code>が置き換えられます。<code>self</code>を返します。
	# 
	# Same as Multiset#map_with, but replaces <code>self</code> by
	# resulting multiset. Returns <code>self</code>.
	def map_with!
		self.to_hash.each_pair do |item, count|
			self.delete(item, count)
			val = yield(item, count)
			self.add(val[0], val[1])
		end
		self
	end
	alias collect_with! map_with!
	
	# <code>self</code>の要素を無作為に1つ選んで返します。
	# すべての要素は等確率で選ばれます。
	#
	# Returns one item in <code>self</code> randomly.
	# All items are selected with the same probability.
	def sample
		pos = Kernel.rand(self.size)
		@entries.each_pair do |item, count|
			pos -= count
			return item if pos < 0
		end
	end
  alias :rand :sample
	
	# <code>self</code>中に含まれる多重集合を平滑化したものを返します。
	#
	# Generates a multiset such that multisets in <code>self</code> are flattened.
	def flatten
		ret = Multiset.new
		self.each do |item|
			if item.kind_of?(Multiset)
				ret += item.flatten
			else
				ret << item
			end
		end
		ret
	end
	
	# <code>self</code>中に含まれる多重集合を平滑化します。
	# 平滑化した多重集合が1つでもあれば<code>self</code>を、
	# そうでなければ<code>nil</code>を返します。
	#
	# Flattens multisets in <code>self</code>.
	# Returns <code>self</code> if any item is flattened,
	# <code>nil</code> otherwise.
	def flatten!
		ret = nil
		self.to_a.each do |item|
			if item.kind_of?(Multiset)
				self.delete(item)
				self.merge!(item.flatten)
				ret = self
			end
		end
		ret
	end
	
	# ブロックに<code>self</code>の要素（重複なし）を順次与え、
	# 結果が偽であった要素のみを集めたMultisetを返します。
	#
	# Gives all items in <code>self</code> (without duplication) to given block,
	# and returns a multiset collecting the items whose results in the block are false.
	def reject
    ret = Multiset.new
		@entries.each_pair do |item, count|
			ret.renew_count(item, count) unless yield(item)
		end
		ret
	end
  
	# ブロックに<code>self</code>の要素（重複なし）と個数の組を順次与え、
	# 結果が偽であった要素のみを集めたMultisetを返します。
	#
	# Gives all pairs of (non-duplicate) items and counts in <code>self</code> to given block,
	# and returns a multiset collecting the items whose results in the block are false.
	def reject_with
    ret = Multiset.new
		@entries.each_pair do |item, count|
			ret.renew_count(item, count) unless yield(item, count)
		end
		ret
	end
  
  # Multiset#delete_ifと同じですが、要素が1つも削除されなければ<code>nil</code>を返します。
  #
  # Same as Multiset#delete_if, but returns <code>nil</code> if no item is deleted.
  def reject!
    ret = nil
    @entries.each_pair do |item, count|
			if yield(item)
        self.delete_all(item)
        ret = self
      end
		end
		ret
	end
	
	# ブロックに<code>self</code>の要素（重複なし）を順次与え、
	# 結果が真であった要素をすべて削除します。
	# <code>self</code>を返します。
	#
	# Gives all items in <code>self</code> (without duplication) to given block,
	# and deletes that item if the block returns true.
	# Returns <code>self</code>.
	def delete_if
		@entries.each_pair do |item, count|
			self.delete_all(item) if yield(item)
		end
		self
	end
	
	# <code>self</code>に含まれるすべての要素（重複なし）とその個数について、
	# その組をブロックに与え、結果が真であった要素をすべて削除します。
	# <code>self</code>を返します。
	#
	# Gives each pair of (non-duplicate) item and its number to given block,
	# and deletes those items if the block returns true.
	# Returns <code>self</code>.
	def delete_with
		@entries.each_pair do |item, count|
			@entries.delete(item) if yield(item, count)
		end
		self
	end
	
	# <code>self</code>の要素を、与えられたブロックからの返り値によって分類します。
	# ブロックからの返り値をキーとして値を対応付けたMultimapを返します。
	#
	# Classify items in <code>self</code> by returned value from block.
	# Returns a Multimap whose values are associated with keys. Keys'
	# are defined by returned value from given block.
	def group_by
		ret = Multimap.new
		@entries.each_pair do |item, count|
			ret[yield(item)].add(item, count)
		end
		ret
	end
  alias :classify :group_by
	
	# Multiset#group_byと同様ですが、ブロックには要素とその個数の組が与えられます。
	#
	# Same as Multiset#group_by, but the pairs of (non-duplicate) items and their counts are given to block.
	def group_by_with
		ret = Multimap.new
		@entries.each_pair do |item, count|
			ret[yield(item, count)].add(item, count)
		end
		ret
	end
  alias :classify_with :group_by_with
  
	# ブロックに<code>self</code>の要素（重複なし）を順次与え、
	# 最初に結果が真であった要素を返します。
	# 見つからなかった場合は、ifnoneが指定されている場合は ifnone.call し、
  # そうでなければnilを返します。
  # ブロックを与えなかった場合、そのためのEnumeratorを返します。
	#
	# Gives all items in <code>self</code> (without duplication) to given block,
	# and returns the first item that makes true the result of the block.
	# If none of the items make it true, ifnone.call is executed if ifnone is specified,
  # otherwise nil is returned.
  # If no block is given, corresponding Enumerator is returned.
  def find(ifnone = nil, &block) # :yields: item
    if block
      find_(ifnone, &block)
    else
      self.to_enum(:find_, ifnone)
    end
  end
  alias :detect :find
  
  def find_(ifnone, &block) # :nodoc:
		@entries.each_pair do |item, count|
      return item if yield(item)
		end
    (ifnone == nil) ? nil : ifnone.call
  end
  private :find_
  
	# Multiset#findと同じですが、ブロックには<code>self</code>の要素とその個数の組が与えられます。
	#
  # The same as Multiset#find, but pairs of (non-duplicate) items and their counts are given to the block.
  def find_with(ifnone = nil, &block) # :yields: item
    if block
      find_with_(ifnone, &block)
    else
      self.to_enum(:find_with_, ifnone)
    end
  end
  alias :detect_with :find_with
  
  def find_with_(ifnone, &block) # :nodoc:
		@entries.each_pair do |item, count|
      return item if yield(item, count)
		end
    (ifnone == nil) ? nil : ifnone.call
  end
  private :find_with_
  
	# ブロックに<code>self</code>の要素（重複なし）を順次与え、
	# 結果が真であった要素を集めた多重集合を返します。
  # ブロックを与えなかった場合、そのためのEnumeratorを返します。
	#
	# Gives all items in <code>self</code> (without duplication) to given block,
	# and returns the Multiset by items that makes true the result of the block.
  # If no block is given, corresponding Enumerator is returned.
  def find_all(&block) # :yields: item
    if block
      find_all_(&block)
    else
      self.to_enum(:find_all_, ifnone)
    end
  end
  alias :select :find_all
  
  def find_all_(&block) # :nodoc:
    ret = Multiset.new
		@entries.each_pair do |item, count|
			ret.renew_count(item, count) if yield(item)
		end
		ret
  end
  private :find_all_
  
	# Multiset#find_allと同じですが、ブロックには<code>self</code>の要素とその個数の組が与えられます。
	#
  # The same as Multiset#find_all, but pairs of (non-duplicate) items and their counts are given to the block.
  def find_all_with(&block) # :yields: item
    if block
      find_all_with_(&block)
    else
      self.to_enum(:find_all_with_, ifnone)
    end
  end
  alias :select_with :find_all_with
  
  def find_all_with_(&block) # :nodoc:
    ret = Multiset.new
		@entries.each_pair do |item, count|
			ret.renew_count(item, count) if yield(item, count)
		end
		ret
  end
  private :find_all_
  
	# <code>pattern</code>の条件を満たした（<code>pattern</code> === item）要素のみを集めた多重集合を返します。
  # ブロックが与えられている場合は、さらにその結果を適用した結果を返します。
	#
  # Collects items in <code>self</code> satisfying <code>pattern</code> (<code>pattern</code> === item).
  # If a block is given, the items are converted by the result of the block.
  def grep(pattern)
    ret = Multiset.new
		@entries.each_pair do |item, count|
			if pattern === item
        ret.add((block_given? ? yield(item) : item), count)
      end
		end
    ret
  end
  
  # ブロックに「1回前のブロック呼び出しの返り値」「<code>self</code>の要素」「その個数」の
  # 3つ組を順次与え、最後にブロックを呼んだ結果を返します。ただし「1回前のブロック呼び出しの返り値」は、
  # 1回目のブロック呼び出しの際については、代わりに<code>init</code>の値が与えられます。
  # 
  # Enumerable#injectと異なり、<code>init</code>は省略できません。
  # またブロックの代わりにSymbolを与えることもできません。
  # 
  # Three elements are given to the block for each (non-duplicate) items:
  # the last result of the block, the item and its count.
  # As for the first block call, the first argument is <code>init</code>.
  # The result of the last block call is returned.
  # 
  # Different from Enumerable#inject, <code>init</code> cannot be omitted.
  # In addition, Symbol cannot be given instead of a block.
  def inject_with(init)
    @entries.each_pair do |item, count|
      init = yield(init, item, count)
		end
    init
  end
  
  # 最大の要素を返します。
  # 要素が存在しない場合はnilを返します。
  # ブロックが与えられた場合は、要素間の大小判定を、ブロックに2つの要素を与えることで行います。
  # 
  # Returns the largest item, or <code>nil</code> if no item is stored in <code>self</code>.
  # If a block is given, their order is judged by giving two items to the block.
  def max(&block) # :yields: a, b
    @entries.keys.max(&block)
  end
  
  # 最小の要素を返します。
  # 要素が存在しない場合はnilを返します。
  # ブロックが与えられた場合は、要素間の大小判定を、ブロックに2つの要素を与えることで行います。
  # 
  # Returns the smallest item, or <code>nil</code> if no item is stored in <code>self</code>.
  # If a block is given, their order is judged by giving two items to the block.
  def min(&block) # :yields: a, b
    @entries.keys.min(&block)
  end
  
  # 最小の要素と最大の要素の組を返します。
  # ブロックが与えられた場合は、要素間の大小判定を、ブロックに2つの要素を与えることで行います。
  # 
  # Returns the pair consisting of the smallest and the largest item.
  # If a block is given, their order is judged by giving two items to the block.
  def minmax(&block) # :yields: a, b
    @entries.keys.minmax(&block)
  end
  
  # ブロックの値を評価した結果が最大になるような要素を返します。
  # 要素が存在しない場合はnilを返します。
  # 
  # Returns the largest item, or <code>nil</code> if no item is stored in <code>self</code>.
  def max_by(&block) # :yields: item
    @entries.keys.max_by(&block)
  end
  
  # ブロックの値を評価した結果が最小になるような要素を返します。
  # 要素が存在しない場合はnilを返します。
  # 
  # Returns the smallest item, or <code>nil</code> if no item is stored in <code>self</code>.
  def min_by(&block) # :yields: item
    @entries.keys.min_by(&block)
  end
  
  # ブロックの値を評価した結果が最小になる要素と最大になる要素の組を返します。
  # 要素が存在しない場合はnilを返します。
  # 
  # Returns the pair consisting of the smallest and the largest item.
  def minmax_by(&block) # :yields: item
    @entries.keys.minmax_by(&block)
  end
  
  # Multiset#max と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  # 
  # Same as Multiset#max, but four arguments: "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  def max_with # :yields: item1, count1, item2, count2
    ret = nil
    @entries.each_pair do |item, count|
      if ret == nil
        ret = [item, count]
      else
        if yield(*ret, item, count) < 0
          ret = [item, count]
        end
      end
    end
    ret == nil ? nil : ret[0]
  end
  
  # Multiset#min と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  # 
  # Same as Multiset#min, but four arguments: "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  def min_with # :yields: item1, count1, item2, count2
    ret = nil
    @entries.each_pair do |item, count|
      if ret == nil
        ret = [item, count]
      else
        if yield(*ret, item, count) > 0
          ret = [item, count]
        end
      end
    end
    ret == nil ? nil : ret[0]
  end
  
  # Multiset#minmax と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  # 
  # Same as Multiset#minmax, but four arguments: "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  def minmax_with # :yields: item1, count1, item2, count2
    ret_min = nil
    ret_max = nil
    @entries.each_pair do |item, count|
      if ret_min == nil
        ret_min = [item, count]
        ret_max = [item, count]
      else
        if yield(*ret_min, item, count) > 0
          ret_min = [item, count]
        elsif yield(*ret_max, item, count) < 0
          ret_max = [item, count]
        end
      end
    end
    ret_min == nil ? [nil, nil] : [ret_min[0], ret_max[0]]
  end
  
  # Multiset#max_by と同様ですが、ブロックには要素とその出現数の組が与えられます。
  # 
  # Same as Multiset#min, but pairs of items and their counts are given to the block.
  def max_by_with(&block) # :yields: item
    tmp = @entries.each_pair.max_by(&block)
    tmp ? tmp[0] : nil # if @entries is not empty, tmp must be a two-element array
  end
  
  # Multiset#min_by と同様ですが、ブロックには要素とその出現数の組が与えられます。
  # 
  # Same as Multiset#max, but pairs of items and their counts are given to the block.
  def min_by_with(&block) # :yields: item
    tmp = @entries.each_pair.min_by(&block)
    tmp ? tmp[0] : nil # if @entries is not empty, tmp must be a two-element array
  end
  
  # Multiset#minmax_by と同様ですが、ブロックには要素とその出現数の組が与えられます。
  # 
  # Same as Multiset#minmax, but pairs of items and their counts are given to the block.
  def minmax_by_with(&block) # :yields: item
    tmp = @entries.each_pair.minmax_by(&block)
    tmp[0] ? [tmp[0][0], tmp[1][0]] : nil
  end
end

class Hash
	# <code>self</code>を多重集合に変換し、その結果を返します。
	# キーを要素、キーに対応する値をその要素の要素数とします。
	# 
	# （例）<code>{:a => 4, :b => 2}.to_multiset # :aを4個、:bを2個含む多重集合</code>
	# 
	# Generates multiset from <code>self</code>.
	# Keys are treated as elements, and values are number of elements
	# in the multiset. For example,
	# 
	# <code>{:a => 4, :b => 2}.to_multiset # Multiset with four :a's and two :b's</code>
	def to_multiset
		ret = Multiset.new
		self.each_pair{ |item, count| ret.renew_count(item, count) }
		ret
	end
end
