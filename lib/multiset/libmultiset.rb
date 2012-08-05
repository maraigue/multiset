#==概要(Basic information)
#
#Rubyによる多重集合（マルチセット）の実装です。
#通常の集合（Rubyでは"set"ライブラリ）と異なり、多重集合は
#同一の要素を複数格納することができます。
#
#メソッド名は基本的にSetクラスに合わせてあります。またSetクラスが持つ
#メソッドの大部分を実装していますが、いくつか未実装なものもあります。
#
#Ruby implementation of multiset.
#Unlike ordinary set(see Ruby documentation for "set" library),
#multiset can contain two or more same items.
#
#Most methods' names are same as those of Set class, and all other than
#a few methods in Set class is implemented on Multiset class.
#
#* <code>Set[:a,:b,:c,:b,:b,:c] => #<Set: {:b, :c, :a}></code>
#* <code>Multiset[:a,:b,:c,:b,:b,:c] => #<Multiset:<tt>#</tt>3 :b, <tt>#</tt>2 :c, <tt>#</tt>1 :a></code>

require "enumerator"

class Multiset
	include Enumerable
	
	#--
	# Constructors
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
		@items = {}
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
		@items.to_multiset
	end
	
	# <code>self</code>を<code>Hash</code>に変換して返します。
	# 生成されるハッシュの構造については、Hash#to_multisetをご覧下さい。
	#
	# Converts <code>self</code> to a <code>Hash</code>.
	# See Hash#to_multiset about format of generated hash.
	def to_hash
		@items.dup
	end
	
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
		Set.new(@items.keys)
	end
	
	# <code>self</code>を配列に変換して返します。
	#
	# Converts <code>self</code> to an array.
	def to_a
		ret = []
		@items.each_pair do |item, count|
			ret.concat Array.new(count, item)
		end
		ret
	end
	
	def hash # :nodoc:
		val = 0
		@items.each_pair do |item, count|
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
	
	# <code>self</code>の内容を<code>other</code>のものに置き換えます。
	# <code>self</code>を返します。
	#
	# Replaces <code>self</code> by <code>other</code>.
	# Returns <code>self</code>.
	def replace(other)
		@items.clear
		other.each_pair do |item, count|
			self.renew_count(item, count)
		end
		self
	end
	
	# <code>self</code>に含まれている要素数を返します。
	#
	# Returns number of all items in <code>self</code>.
	def size
		@items.inject(0){ |sum, item| sum += item[1] }
	end
	alias length size
	
	# <code>self</code>に要素がないかどうかを返します。
	#
	# Returns whether <code>self</code> has no item.
	def empty?
		@items.empty?
	end
	
	# <code>self</code>に含まれている要素（重複は除く）からなる配列を返します。
	#
	# Returns an array with all items in <code>self</code>, without duplication.
	def items
		@items.keys
	end
	
	# <code>self</code>の要素をすべて削除します。
	# <code>self</code>を返します。
	#
	# Deletes all items in <code>self</code>.
	# Returns <code>self</code>.
	def clear
		@items.clear
		self
	end
	
	# <code>item</code>が<code>self</code>中に含まれているかを返します。
	#
	# Returns whether <code>self</code> has <code>item</code>.
	def include?(item)
		@items.has_key?(item)
	end
	alias member? include?
	
	# <code>self</code>中に含まれる<code>item</code>の個数を返します。
	#
	# Returns number of <code>item</code>s in <code>self</code>.
	def count(item)
		@items.has_key?(item) ? @items[item] : 0
	end
	
	# <code>self</code>に含まれるすべての要素について繰り返します。
	# <code>self</code>を返します。
	#
	# Iterates for each item in <code>self</code>.
	# Returns <code>self</code>.
	def each
		@items.each_pair do |item, count|
			count.times{ yield item }
		end
		self
	end
	
	# <code>self</code>に含まれるすべての要素について、重複を許さずに繰り返します。
	# <code>self</code>を返します。
	#
	# Iterates for each item in <code>self</code>, without duplication.
	# Returns <code>self</code>.
	def each_item(&block) # :yields: item
		@items.each_key(&block)
		self
	end
	
	# <code>self</code>に含まれるすべての要素とその個数について繰り返します。
	# <code>self</code>を返します。
	#
	# Iterates for each pair of item and its number in <code>self</code>.
	# Returns <code>self</code>.
	def each_pair(&block) # :yields: item, count
		@items.each_pair(&block)
		self
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
			@items[item] = n
		else
			@items.delete(item)
		end
		self
	end
	
	# <code>self</code>の各要素をブロックに与え、返り値を集めたものからなる
	# 多重集合を生成します。
	# 
	# Gives all items in <code>self</code> to given block,
	# and generates a new multiset whose values are returned value from the block.
	def map
		ret = Multiset.new
		self.each do |item|
			ret << yield(item)
		end
		ret
	end
	alias collect map
	
	# Multiset#mapと同様ですが、結果として生成される多重集合で<code>self</code>が
	# 置き換えられます。<code>self</code>を返します。
	# 
	# Same as Multiset#map, but replaces <code>self</code> by resulting multiset.
	# Returns <code>self</code>.
	def map!
		self.to_a.each do |item|
			self.delete(item)
			self << yield(item)
		end
		self
	end
	alias collect! map!
	
	# <code>self</code>の要素とその個数の組をブロックに与えます。
	# ブロックから2要素の配列を受け取り、前者を要素、後者をその個数とした
	# 多重集合を生成します。
	# 
	# Gives all pairs of items and their numbers in <code>self</code> to
	# given block. The block must return an array of two items.
	# Generates a new multiset whose values and numbers are the first and
	# second item of returned array, respectively.
	def map_with
		ret = Multiset.new
		self.each_pair do |item, count|
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
	# All items are selected with same probability.
	def rand
		pos = Kernel.rand(self.size)
		@items.each_pair do |item, count|
			pos -= count
			return item if pos < 0
		end
	end
	
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
		check = self.items.dup
		check.concat(other.items)
		check.each do |item|
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
		@items.delete(item)
		self
	end
	
	# delete_ifと同じですが、要素が1つも削除されなければ<code>nil</code>を返します。
	#
	# Same as delete_if, but returns <code>nil</code> if no item is deleted.
	def reject!
		ret = nil
		self.to_a.each do |item|
			if yield(item)
				ret = self if self.delete(item) == self
			end
		end
		ret
	end
	
	# ブロックに<code>self</code>の要素を順次与え、
	# 結果が真であった要素をすべて削除します。
	# <code>self</code>を返します。
	#
	# Gives all items in <code>self</code> to given block,
	# and deletes that item if the block returns true.
	# Returns <code>self</code>.
	def delete_if
		self.to_a.each do |item|
			@items.delete(item) if yield(item)
		end
		self
	end
	
	# <code>self</code>に含まれるすべての要素とその個数について、
	# その組をブロックに与え、結果が真であった要素をすべて削除します。
	# <code>self</code>を返します。
	#
	# Gives each pair of item and its number to given block,
	# and deletes those items if the block returns true.
	# Returns <code>self</code>.
	def delete_with
		@items.each_pair do |item, count|
			@items.delete(item) if yield(item, count)
		end
		self
	end
	
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
	
	# <code>self</code>の要素を、与えられたブロックからの返り値によって分類します。
	# ブロックからの返り値をキーとして値を対応付けたMultimapを返します。
	#
	# Classify items in <code>self</code> by returned value from block.
	# Returns a Multimap whose values are associated with keys. Keys'
	# are defined by returned value from given block.
	def classify
		ret = Multimap.new
		self.each do |item|
			ret[yield(item)].add(item)
		end
		ret
	end
	
	# classifyと同様ですが、ブロックには要素とその個数の組が与えられます。
	#
	# Same as classify, but the pair of item and its number is given to block.
	def classify_with
		ret = Multimap.new
		self.each_pair do |item, count|
			ret[yield(item, count)].add(item, count)
		end
		ret
	end
	
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
		self.each_pair do |item, count|
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
