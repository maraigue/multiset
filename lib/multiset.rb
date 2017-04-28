#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "enumerator"
require "multimap"

#==Basic information 概要
#
# A Ruby implementation of multiset.
# Unlike ordinary set (see Ruby documentation for "set" library),
# multiset can contain two or more same items.
#
# Methods' names are basically consistent with those of Set class.
#
# * <code>Set[:a,:b,:c,:b,:b,:c] => #<Set: {:b, :c, :a}></code>
# * <code>Multiset[:a,:b,:c,:b,:b,:c] => #<Multiset:<tt>#</tt>3 :b, <tt>#</tt>2 :c, <tt>#</tt>1 :a></code>
#
# Rubyによる多重集合（マルチセット）の実装です。
# 通常の集合（Rubyでは"set"ライブラリ）と異なり、多重集合は
# 同一の要素を複数格納することができます。
#
# メソッド名は基本的にSetクラスに合わせてあります。

class Multiset
  VERSION = "0.5.3"

  include Enumerable
  
  #--
  # ============================================================
  # Constructor
  # コンストラクタ
  # ============================================================
  #++
  
  # Generates a multiset from items in <code>list</code>.
  # If <code>list</code> is omitted, returns empty multiset.
  #
  # <code>list</code> must be an object including <code>Enumerable</code>.
  # Otherwise, <code>ArgumentError</code> is raised.
  #
  # <code>list</code>に含まれる要素からなる多重集合を生成します。
  # <code>list</code>を省略した場合、空の多重集合を生成します。
  #
  # <code>list</code>には<code>Enumerable</code>であるオブジェクトのみ
  # 指定できます。そうでない場合、例外<code>ArgumentError</code>が
  # 発生します。
  def initialize(list = nil)
    @entries = {}
    if list.kind_of?(Enumerable)
      list.each{ |item| add item }
    elsif list != nil
      raise ArgumentError, "Item list must be an instance including 'Enumerable' module"
    end
  end
  
  # Generates a multiset from items in <code>list</code>.
  # Unlike using <code>Multiset.new</code>, each argument is one item in generated multiset.
  #
  # This method is mainly used when you generate a multiset from literals.
  #
  # <code>list</code>に含まれる要素からなる多重集合を生成します。
  # <code>Multiset.new</code>を用いる場合と異なり、引数の1つ1つが多重集合の要素になります。
  #
  # 主に、リテラルから多重集合を生成するのに用います。
  def Multiset.[](*list)
    Multiset.new(list)
  end
  
  # Generates a multiset by converting <code>object</code>.
  # * If <code>object</code> is an instance of Multiset, returns
  #   duplicated <code>object</code>.
  # * If <code>object</code> is not an instance of Multiset and has
  #   the method <code>each_pair</code>,
  #   for each pair of two arguments from <code>each_pair</code>,
  #   the first argument becomes the item in multiset and
  #   the second argument becomes its number in the multiset.
  #   See also Hash#to_multiset .
  # * If <code>object</code> does not have the method <code>each_pair</code>
  #   and <code>object</code> includes <code>Enumerable</code>, this method
  #   works the same as Multiset#new .
  # * Otherwise, <code>ArgumentError</code> is raised.
  #
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
  
  # Generates a Multiset from string, separated by lines.
  # 
  # 文字列を行単位で区切ってMultisetにします。
  def Multiset.from_lines(str)
    Multiset.new(str.enum_for(:each_line))
  end
  
  # If a string is given, it works as Multiset.from_lines,
  # otherwise as Multiset.parse.
  # 
  # 文字列が渡された場合は、Multiset.from_linesと同じ挙動。
  # それ以外の場合は、Multiset.parseと同じ挙動。
  def Multiset.parse_force(object)
    if object.kind_of?(String)
      Multiset.from_lines(object)
    else
      Multiset.parse(object)
    end
  end
  
  # Returns duplicated <code>self</code>.
  #
  # <code>self</code>の複製を生成して返します。
  def dup
    @entries.to_multiset
  end
  
  # Converts <code>self</code> to a <code>Hash</code>.
  # See Hash#to_multiset about format of generated hash.
  #
  # <code>self</code>を<code>Hash</code>に変換して返します。
  # 生成されるハッシュの構造については、Hash#to_multisetをご覧下さい。
  def to_hash
    @entries.dup
  end
  
  #--
  # ============================================================
  # Basic functions such as converting into other types
  # 別の型への変換、基本的な関数など
  # ============================================================
  #++
  
  # Converts <code>self</code> to ordinary set
  # (The <code>Set</code> class attached to Ruby by default).
  #
  # <code>require "set"</code> is performed when this method is called.
  #
  # Note: To convert an instance of Set to Multiset, use
  # <code>Multiset.new(instance_of_set)</code>.
  #
  # <code>self</code>を通常の集合（Ruby標準添付の<code>Set</code>）に
  # 変換したものを返します。
  #
  # このメソッドを呼び出すと、<code>require "set"</code>が行われます。
  #
  # 注：逆に、SetのインスタンスをMultisetに変換するには、
  # <code>Multiset.new(instance_of_set)</code>で可能です。
  def to_set
    require "set"
    Set.new(@entries.keys)
  end
  
  # Converts <code>self</code> to an array.
  #
  # <code>self</code>を配列に変換して返します。
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
  # Basic operations such as ones required for other methods
  # 基本操作（他のメソッドを定義するのに頻出するメソッドなど）
  # ============================================================
  #++
  
  # Replaces <code>self</code> by <code>other</code>.
  # Returns <code>self</code>.
  #
  # <code>self</code>の内容を<code>other</code>のものに置き換えます。
  # <code>self</code>を返します。
  def replace(other)
    @entries.clear
    other.each_pair do |item, count|
      self.renew_count(item, count)
    end
    self
  end
  
  # Returns number of all items in <code>self</code>.
  #
  # <code>self</code>に含まれている要素数を返します。
  def size
    @entries.inject(0){ |sum, item| sum += item[1] }
  end
  alias length size
  
  # Returns whether <code>self</code> has no item.
  #
  # <code>self</code>に要素がないかどうかを返します。
  def empty?
    @entries.empty?
  end
  
  # Returns an array with all items in <code>self</code>, without duplication.
  #
  # <code>self</code>に含まれている要素（重複は除く）からなる配列を返します。
  def items
    @entries.keys
  end
  
  # Deletes all items in <code>self</code>.
  # Returns <code>self</code>.
  #
  # <code>self</code>の要素をすべて削除します。
  # <code>self</code>を返します。
  def clear
    @entries.clear
    self
  end
  
  # Returns whether <code>self</code> has <code>item</code>.
  #
  # <code>item</code>が<code>self</code>中に含まれているかを返します。
  def include?(item)
    @entries.has_key?(item)
  end
  alias member? include?
  
  # Lists all items with duplication in <code>self</code>.
  # Items are deliminated with <code>delim</code>, and items are
  # converted to string in the given block.
  # If block is omitted, Object#inspect is used.
  #
  # <code>self</code>の全要素を（重複を許して）並べた文字列を返します。
  # 要素間の区切りは<code>delim</code>の値を用い、
  # 各要素の表示形式は与えられたブロックの返り値（なければObject#inspect）を用います。
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
  
  # Lists all items without duplication and its number in <code>self</code>.
  # Items are deliminated with <code>delim</code>, and items are
  # converted to string in the given block.
  # If block is omitted, Object#inspect is used.
  #
  # <code>self</code>の要素と要素数の組を並べた文字列を返します。
  # 要素間の区切りは<code>delim</code>の値を用い、
  # 各要素の表示形式は与えられたブロックの返り値（なければObject#inspect）を用います。
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
  # The number of elements in a multiset
  # マルチセットの要素数
  # ============================================================
  #++
  
  # Returns number of <code>item</code>s in <code>self</code>.
  # If the <code>item</code> is omitted, the value is same as Multiset#size.
  # If a block is given, each element (without duplication) is given to
  # the block, and returns the number of elements (including duplication)
  # that returns true in the block.
  #
  # <code>self</code>中に含まれる<code>item</code>の個数を返します。
  # 引数を指定しない場合は、Multiset#sizeと同じです。
  # ブロックを指定することもでき、その場合は（重複しない）各要素をブロックに与え、
  # 条件を満たした（結果が真であった）要素がMultiset内にいくつ入っているかを数えます。
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
  
  # Sets the number of <code>item</code> in <code>self</code> as <code>number</code>.
  # If <code>number</code> is negative, it is considered as <code>number = 0</code>.
  # Returns <code>self</code> if succeeded, <code>nil</code> otherwise.
  #
  # <code>self</code>に含まれる<code>item</code>の個数を<code>number</code>個にします。
  # <code>number</code>が負の数であった場合は、<code>number = 0</code>とみなします。
  # 成功した場合は<code>self</code>を、失敗した場合は<code>nil</code>を返します。
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
  
  # Adds <code>addcount</code> number of <code>item</code>s to <code>self</code>.
  # Returns <code>self</code> if succeeded, or <code>nil</code> if failed.
  #
  # <code>self</code>に、<code>addcount</code>個の<code>item</code>を追加します。
  # 成功した場合は<code>self</code>を、失敗した場合は<code>nil</code>を返します。
  def add(item, addcount = 1)
    return nil if addcount == nil
    a = addcount.to_i
    return nil if a <= 0
    self.renew_count(item, self.count(item) + a)
  end
  alias << add
  
  # Deletes <code>delcount</code> number of <code>item</code>s
  # from <code>self</code>.
  # Returns <code>self</code> if succeeded, <code>nil</code> otherwise.
  #
  # <code>self</code>から、<code>delcount</code>個の<code>item</code>を削除します。
  # 成功した場合は<code>self</code>を、失敗した場合は<code>nil</code>を返します。
  def delete(item, delcount = 1)
    return nil if delcount == nil || !self.include?(item)
    d = delcount.to_i
    return nil if d <= 0
    self.renew_count(item, self.count(item) - d)
  end
  
  # Deletes all <code>item</code>s in <code>self</code>.
  # Returns <code>self</code>.
  #
  # <code>self</code>に含まれる<code>item</code>をすべて削除します。
  # <code>self</code>を返します。
  def delete_all(item)
    @entries.delete(item)
    self
  end
  
  #--
  # ============================================================
  # Relationships about inclusions
  # 包含関係の比較
  # ============================================================
  #++
  
  # Iterates for each item in <code>self</code> and <code>other</code>,
  # without duplication. If the given block returns false, then iteration
  # immediately ends and returns false.
  # Returns true if the given block returns true for all of iteration.
  # 
  # This method is defined for methods superset?, subset?, ==.
  #
  # <code>self</code>と<code>other</code>が持つすべての要素（重複なし）について
  # 繰り返し、ブロックの返り値が偽であるものが存在すればその時点でfalseを返します。
  # すべての要素について真であればtrueを返します。
  #
  # このメソッドはsuperset?、subset?、== のために定義されています。
  def compare_set_with(other) # :nodoc: :yields: number_in_self, number_in_other
    (self.items | other.items).each do |item|
      return false unless yield(self.count(item), other.count(item))
    end
    true
  end
  
  # Returns whether <code>self</code> is a superset of <code>other</code>,
  # that is, for any item, the number of it in <code>self</code> is
  # equal to or larger than that in <code>other</code>.
  # 
  # <code>self</code>が<code>other</code>を含んでいるかどうかを返します。
  # すなわち、いかなる要素についても、それが<code>self</code>に含まれている
  # 個数が<code>other</code>に含まれている数以上であるかを返します。
  def superset?(other)
    unless other.instance_of?(Multiset)
      raise ArgumentError, "Argument must be a Multiset"
    end
    compare_set_with(other){ |s, o| s >= o }
  end
  
  # Returns whether <code>self</code> is a proper superset of <code>other</code>,
  # that is, it returns true if superset? is satisfied and
  # <code>self</code> is not equal to <code>other</code>.
  #
  # <code>self</code>が<code>other</code>を真に含んでいるかどうかを返します。
  # すなわち、 superset? の条件に加えて両者が一致しなければ真となります。
  def proper_superset?(other)
    unless other.instance_of?(Multiset)
      raise ArgumentError, "Argument must be a Multiset"
    end
    self.superset?(other) && self != other
  end

  # Returns whether <code>self</code> is a subset of <code>other</code>,
  # that is, for any item, the number of it in <code>self</code> is
  # equal to or smaller than that in <code>other</code>.
  # 
  # <code>self</code>が<code>other</code>を含んでいるかどうかを返します。
  # すなわち、いかなる要素についても、それが<code>self</code>に含まれている
  # 個数が<code>other</code>に含まれている数以下であるかを返します。
  def subset?(other)
    unless other.instance_of?(Multiset)
      raise ArgumentError, "Argument must be a Multiset"
    end
    compare_set_with(other){ |s, o| s <= o }
  end
  
  # Returns whether <code>self</code> is a proper subset of <code>other</code>,
  # that is, it returns true if subset? is satisfied and
  # <code>self</code> is not equal to <code>other</code>.
  #
  # <code>self</code>が<code>other</code>に真に含まれているかどうかを返します。
  # すなわち、 subset? の条件に加えて両者が一致しなければ真となります。
  def proper_subset?(other)
    unless other.instance_of?(Multiset)
      raise ArgumentError, "Argument must be a Multiset"
    end
    self.subset?(other) && self != other
  end
  
  # Returns whether <code>self</code> is equal to <code>other</code>.
  #
  # <code>self</code>が<code>other</code>と等しいかどうかを返します。
  def ==(other)
    return false unless other.instance_of?(Multiset)
    compare_set_with(other){ |s, o| s == o }
  end
  
  #--
  # ============================================================
  # Other operations for two multisets
  # その他、2つのMultisetについての処理
  # ============================================================
  #++
  
  # Returns a multiset merging <code>self</code> and <code>other</code>.
  #
  # <code>self</code>と<code>other</code>の要素を合わせた多重集合を返します。
  def merge(other)
    ret = self.dup
    other.each_pair do |item, count|
      ret.add(item, count)
    end
    ret
  end
  alias + merge
  
  # Merges <code>other</code> to <code>self</code>.
  # See also Multiset#merge .
  # Returns <code>self</code>.
  #
  # <code>self</code>に<code>other</code>の要素を追加します。
  # Multiset#merge も参照してください。
  # <code>self</code>を返します。
  def merge!(other)
    other.each_pair do |item, count|
      self.add(item, count)
    end
    self
  end
  
  # Returns a multiset such that items in <code>other</code> are removed from <code>self</code>,
  # where 'removed' means that, for each item in <code>other</code>,
  # the items of the number in <code>other</code> are removed from <code>self</code>.
  #
  # <code>self</code>から<code>other</code>の要素を取り除いた多重集合を返します。
  # ここで「取り除く」ことは、<code>other</code>の各要素について、
  # それを<code>other</code>にある個数分<code>self</code>から取り除くことをいいます。
  def subtract(other)
    ret = self.dup
    other.each_pair do |item, count|
      ret.delete(item, count)
    end
    ret
  end
  alias - subtract
  
  # Removes items in <code>other</code> from <code>self</code>.
  # See also Multiset#subtract .
  # Returns <code>self</code>.
  #
  # <code>self</code>から<code>other</code>の要素を削除します。
  # Multiset#subtract も参照してください。
  # <code>self</code>を返します。
  def subtract!(other)
    other.each_pair do |item, count|
      self.delete(item, count)
    end
    self
  end
  
  # Returns the intersection of <code>self</code> and <code>other</code>,
  # that is, for each item both in <code>self</code> and <code>other</code>,
  # the multiset includes it in the smaller number of the two.
  #
  # <code>self</code>と<code>other</code>の積集合からなる多重集合を返します。
  # すなわち、<code>self</code>と<code>other</code>の両方に存在する要素について、
  # 少ないほうの個数を持った多重集合を返します。
  def &(other)
    ret = Multiset.new
    (self.items & other.items).each do |item|
      ret.renew_count(item, [self.count(item), other.count(item)].min)
    end
    ret
  end
  
  # Returns the union of <code>self</code> and <code>other</code>,
  # that is, for each item either or both in <code>self</code> and <code>other</code>,
  # the multiset includes it in the larger number of the two.
  #
  # <code>self</code>と<code>other</code>の和集合からなる多重集合を返します。
  # すなわち、<code>self</code>と<code>other</code>の少なくとも一方に存在する要素について、
  # 多いほうの個数を持った多重集合を返します。
  def |(other)
    ret = self.dup
    other.each_pair do |item, count|
      ret.renew_count(item, [self.count(item), count].max)
    end
    ret
  end
  
  #--
  # ============================================================
  # Processes for single multiset
  # 1つのMultisetの各要素についての処理
  # ============================================================
  #++
  
  # Iterates for each item in <code>self</code>.
  # Returns <code>self</code>.
  # An Enumerator will be returned if no block is given.
  # 
  # This method is ineffective since the same element in the Multiset
  # can be given to the block for many times,
  # so that it behaves the same as Enumerable#each.
  # Please consider using Multiset#each_item or Multiset#each_pair: for example,
  # a Multiset with 100 times "a" will call the given block for 100 times for Multiset#each,
  # while only once for Multiset#each_pair.
  #
  # <code>self</code>に含まれるすべての要素について繰り返します。
  # <code>self</code>を返します。
  # ブロックが与えられていない場合、Enumeratorを返します。
  # 
  # このメソッドは Enumerable#each の挙動に合わせ、同じ要素を何度もブロックに
  # 渡すため、効率が悪いです。Multiset#each_item, Multiset#each_pairの利用もご検討下さい。
  # 例えば「"a"が100個入ったMultiset」をeachで繰り返すと100回の処理が行われますが、
  # each_pairなら1回で済みます。
  def each
    if block_given?
      @entries.each_pair do |item, count|
        count.times{ yield item }
      end
      self
    else
      Enumerator.new(self, :each)
    end
  end
  
  # Iterates for each item in <code>self</code>, without duplication.
  # Returns <code>self</code>.
  # An Enumerator will be returned if no block is given.
  #
  # <code>self</code>に含まれるすべての要素について、重複を許さずに繰り返します。
  # <code>self</code>を返します。
  # ブロックが与えられていない場合、Enumeratorを返します。
  def each_item(&block) # :yields: item
    if block
      @entries.each_key(&block)
      self
    else
      @entries.each_key
    end
  end
  
  # Iterates for each pair of (non-duplicated) item and its number in <code>self</code>.
  # Returns <code>self</code>.
  # An Enumerator will be returned if no block is given.
  #
  # <code>self</code>に含まれるすべての要素（重複なし）とその個数について繰り返します。
  # <code>self</code>を返します。
  # ブロックが与えられていない場合、Enumeratorを返します。
  def each_with_count(&block) # :yields: item, count
    if block
      @entries.each_pair(&block)
      self
    else
      @entries.each_pair
    end
  end
  alias :each_pair :each_with_count
  
  # Gives all items in <code>self</code> (without duplication) to given block,
  # and generates a new multiset whose values are returned value from the block.
  #
  # <code>self</code>の各要素（重複なし）をブロックに与え、返り値を集めたものからなる
  # 多重集合を生成します。
  def map # :yields: item
    ret = Multiset.new
    @entries.each_pair do |item, count|
      ret.add(yield(item), count)
    end
    ret
  end
  alias collect map
  
  # Same as Multiset#map, except that <code>self</code> is replaced by the resulted multiset.
  # Returns <code>self</code>.
  #
  # Multiset#mapと同様の処理を行いますが、結果として生成される多重集合で<code>self</code>が
  # 置き換えられます。<code>self</code>を返します。
  def map!(&block) # :yields: item
    self.replace(self.map(&block))
    self
  end
  alias collect! map!
  
  # Gives all pairs of (non-duplicated) items and their numbers in <code>self</code> to
  # given block. The block must return an array of two items.
  # Generates a new multiset whose values and numbers are the first and
  # second item of returned array, respectively.
  #
  # <code>self</code>の要素（重複なし）とその個数の組をブロックに与えます。
  # ブロックから2要素の配列を受け取り、前者を要素、後者をその個数とした
  # 多重集合を生成します。
  def map_with
    ret = Multiset.new
    @entries.each_pair do |item, count|
      val = yield(item, count)
      ret.add(val[0], val[1])
    end
    ret
  end
  alias collect_with map_with
  
  # Same as Multiset#map_with, except that <code>self</code> by
  # the resulted multiset. Returns <code>self</code>.
  # 
  # Multiset#map_withと同様ですが、結果として生成される多重集合で
  # <code>self</code>が置き換えられます。<code>self</code>を返します。
  def map_with!
    self.to_hash.each_pair do |item, count|
      self.delete(item, count)
      val = yield(item, count)
      self.add(val[0], val[1])
    end
    self
  end
  alias collect_with! map_with!
  
  # Returns one item in <code>self</code> at random
  # in the same probability.
  # Returns <code>nil</code> in case the multiset is empty.
  #
  # <code>self</code>の要素を無作為に1つ選んで返します。
  # すべての要素は等確率で選ばれます。
  # 空のMultisetに対して呼び出した場合は<code>nil</code>を返します。
  def sample
    return nil if empty?
    pos = Kernel.rand(self.size)
    @entries.each_pair do |item, count|
      pos -= count
      return item if pos < 0
    end
  end
  alias :rand :sample
  
  # Generates a multiset such that multisets in <code>self</code> are flattened.
  #
  # <code>self</code>中に含まれる多重集合を平滑化したものを返します。
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
  
  # Flattens multisets in <code>self</code>.
  # Returns <code>self</code> if any item is flattened,
  # <code>nil</code> otherwise.
  #
  # <code>self</code>中に含まれる多重集合を平滑化します。
  # 平滑化した多重集合が1つでもあれば<code>self</code>を、
  # そうでなければ<code>nil</code>を返します。
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
  
  # Gives all items in <code>self</code> (without duplication) to given block,
  # and returns a multiset collecting the items such that the block returns false.
  #
  # ブロックに<code>self</code>の要素（重複なし）を順次与え、
  # 結果が偽であった要素のみを集めたMultisetを返します。
  def reject
    ret = Multiset.new
    @entries.each_pair do |item, count|
      ret.renew_count(item, count) unless yield(item)
    end
    ret
  end
  
  # Gives all pairs of (non-duplicated) items and counts in <code>self</code> to given block,
  # and returns a multiset collecting the items such that the block returns false.
  #
  # ブロックに<code>self</code>の要素（重複なし）と個数の組を順次与え、
  # 結果が偽であった要素のみを集めたMultisetを返します。
  def reject_with
    ret = Multiset.new
    @entries.each_pair do |item, count|
      ret.renew_count(item, count) unless yield(item, count)
    end
    ret
  end
  
  # Same as Multiset#delete_if except that this returns <code>nil</code> if no item is deleted.
  #
  # Multiset#delete_ifと似ますが、要素が1つも削除されなければ<code>nil</code>を返します。
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
  
  # Gives all items in <code>self</code> (without duplication) to given block,
  # and deletes the items such that the block returns true.
  # Returns <code>self</code>.
  #
  # ブロックに<code>self</code>の要素（重複なし）を順次与え、
  # 結果が真であった要素をすべて削除します。
  # <code>self</code>を返します。
  def delete_if
    @entries.each_pair do |item, count|
      self.delete_all(item) if yield(item)
    end
    self
  end
  
  # Gives each pair of (non-duplicated) item and its number to given block,
  # and deletes those items such that the block returns true.
  # Returns <code>self</code>.
  #
  # <code>self</code>に含まれるすべての要素（重複なし）とその個数について、
  # その組をブロックに与え、結果が真であった要素をすべて削除します。
  # <code>self</code>を返します。
  def delete_with
    @entries.each_pair do |item, count|
      @entries.delete(item) if yield(item, count)
    end
    self
  end
  
  # Classify items in <code>self</code> by returned value from block.
  # Returns a Multimap whose values are associated with keys, where
  # the keys are the returned value from given block.
  #
  # <code>self</code>の要素を、与えられたブロックからの返り値によって分類します。
  # ブロックからの返り値をキーとして値を対応付けたMultimapを返します。
  def group_by
    ret = Multimap.new
    @entries.each_pair do |item, count|
      ret[yield(item)].add(item, count)
    end
    ret
  end
  alias :classify :group_by
  
  # Same as Multiset#group_by except that the pairs of (non-duplicated) items and
  # their counts are given to block.
  #
  # Multiset#group_byと同様ですが、ブロックには要素とその個数の組が与えられます。
  def group_by_with
    ret = Multimap.new
    @entries.each_pair do |item, count|
      ret[yield(item, count)].add(item, count)
    end
    ret
  end
  alias :classify_with :group_by_with
  
  # Gives all items in <code>self</code> (without duplication) to given block,
  # and returns the first item that makes true the result of the block.
  # If none of the items make it true, ifnone.call is executed if ifnone is specified,
  # otherwise nil is returned.
  # If no block is given, corresponding Enumerator is returned.
  #
  # ブロックに<code>self</code>の要素（重複なし）を順次与え、
  # 最初に結果が真であった要素を返します。
  # 見つからなかった場合は、ifnoneが指定されている場合は ifnone.call し、
  # そうでなければnilを返します。
  # ブロックを与えなかった場合、そのためのEnumeratorを返します。
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
  
  # The same as Multiset#find except that the pairs of (non-duplicated) items and
  # their counts are given to the block.
  #
  # Multiset#findと似ますが、ブロックには<code>self</code>の要素とその個数の組が与えられます。
  def find_with(ifnone = nil, &block) # :yields: item, count
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
  
  # Gives all items in <code>self</code> (without duplication) to given block,
  # and returns the Multiset by items that makes true the result of the block.
  # If no block is given, corresponding Enumerator is returned.
  #
  # ブロックに<code>self</code>の要素（重複なし）を順次与え、
  # 結果が真であった要素を集めた多重集合を返します。
  # ブロックを与えなかった場合、そのためのEnumeratorを返します。
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
  
  # The same as Multiset#find_all except that the pairs of (non-duplicated) items and
  # their counts are given to the block.
  #
  # Multiset#find_allと似ますが、ブロックには<code>self</code>の要素とその個数の組が与えられます。
  def find_all_with(&block) # :yields: item, count
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
  private :find_all_with_
  
  # Collects items in <code>self</code> satisfying <code>pattern</code> (<code>pattern</code> === item).
  # If a block is given, the items are converted by the result of the block.
  #
  # <code>pattern</code>の条件を満たした（<code>pattern</code> === item）要素のみを集めた多重集合を返します。
  # ブロックが与えられている場合は、さらにその結果を適用した結果を返します。
  def grep(pattern)
    ret = Multiset.new
    @entries.each_pair do |item, count|
      if pattern === item
        ret.add((block_given? ? yield(item) : item), count)
      end
    end
    ret
  end
  
  # Three elements are given to the block for each (non-duplicated) items in <code>self</code>:
  # the last result of the block, the item, and its number in <code>self</code>.
  # As for the first block call, the first argument is <code>init</code>.
  # The result of the last block call is returned.
  # 
  # Different from Enumerable#inject, <code>init</code> cannot be omitted.
  # In addition, Symbol cannot be given instead of a block.
  # 
  # ブロックに「1回前のブロック呼び出しの返り値」「<code>self</code>の要素」「その個数」の
  # 3つ組を順次与え、最後にブロックを呼んだ結果を返します。ただし「1回前のブロック呼び出しの返り値」は、
  # 1回目のブロック呼び出しの際については、代わりに<code>init</code>の値が与えられます。
  # 
  # Enumerable#injectと異なり、<code>init</code>は省略できません。
  # またブロックの代わりにSymbolを与えることもできません。
  def inject_with(init)
    @entries.each_pair do |item, count|
      init = yield(init, item, count)
    end
    init
  end
  
  # Returns the largest item in <code>self</code>,
  # or <code>nil</code> if no item is stored in <code>self</code>.
  # If a block is given, they are ordered by giving pairs of items to the block.
  # 
  # 最大の要素を返します。
  # 要素が存在しない場合はnilを返します。
  # ブロックが与えられた場合は、要素間の大小判定を、ブロックに2つの要素を与えることで行います。
  def max(&block) # :yields: a, b
    @entries.keys.max(&block)
  end
  
  # Returns the smallest item in <code>self</code>,
  # or <code>nil</code> if no item is stored in <code>self</code>.
  # If a block is given, they are ordered by giving pairs of items to the block.
  # 
  # 最小の要素を返します。
  # 要素が存在しない場合はnilを返します。
  # ブロックが与えられた場合は、要素間の大小判定を、ブロックに2つの要素を与えることで行います。
  def min(&block) # :yields: a, b
    @entries.keys.min(&block)
  end
  
  # Returns the pair consisting of the smallest and the largest item in <code>self</code>,
  # or <code>nil</code> if no item is stored in <code>self</code>.
  # If a block is given, they are ordered by giving pairs of items to the block.
  # 
  # 最小の要素と最大の要素の組を返します。
  # ブロックが与えられた場合は、要素間の大小判定を、ブロックに2つの要素を与えることで行います。
  def minmax(&block) # :yields: a, b
    @entries.keys.minmax(&block)
  end
  
  # Returns the largest item by comparing the items in <code>self</code>
  # by the results of the block.
  # If no item is stored in <code>self</code>, <code>nil</code> is returned.
  # 
  # ブロックの値を評価した結果が最大になるような要素を返します。
  # 要素が存在しない場合はnilを返します。
  def max_by(&block) # :yields: item
    @entries.keys.max_by(&block)
  end
  
  # Returns the largest item by comparing the items in <code>self</code>
  # by the results of the block.
  # If no item is stored in <code>self</code>, <code>nil</code> is returned.
  #
  # ブロックの値を評価した結果が最小になるような要素を返します。
  # 要素が存在しない場合はnilを返します。
  def min_by(&block) # :yields: item
    @entries.keys.min_by(&block)
  end
  
  # Returns the pair consisting of the smallest and the largest items  in <code>self</code>
  # by comparing the items by the results of the block.
  # If no item is stored in <code>self</code>, <code>nil</code> is returned.
  #
  # ブロックの値を評価した結果が最小になる要素と最大になる要素の組を返します。
  # 要素が存在しない場合はnilを返します。
  def minmax_by(&block) # :yields: item
    @entries.keys.minmax_by(&block)
  end
  
  # Same as Multiset#max except that the following four:
  # "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  #
  # Multiset#max と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  def max_with # :yields: item1, count1, item2, count2
    tmp = @entries.each_pair.max{ |a, b| yield(a[0], a[1], b[0], b[1]) }
    tmp ? tmp[0] : nil
  end
  
  # Same as Multiset#min except that the following four:
  # "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  #
  # Multiset#min と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  def min_with # :yields: item1, count1, item2, count2
    tmp = @entries.each_pair.min{ |a, b| yield(a[0], a[1], b[0], b[1]) }
    tmp ? tmp[0] : nil
  end
  
  # Same as Multiset#minmax except that the following four:
  # "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  #
  # Multiset#minmax と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  def minmax_with # :yields: item1, count1, item2, count2
    tmp = @entries.each_pair.minmax{ |a, b| yield(a[0], a[1], b[0], b[1]) }
    tmp ? [tmp[0][0], tmp[1][0]] : nil
  end
  
  # Same as Multiset#max_by except that pairs of (non-duplicated) items and their counts
  # are given to the block.
  #
  # Multiset#max_by と同様ですが、ブロックには要素（重複なし）とその出現数の組が与えられます。
  def max_by_with(&block) # :yields: item, count
    tmp = @entries.each_pair.max_by(&block)
    tmp ? tmp[0] : nil # if @entries is not empty, tmp must be a two-element array
  end
  
  # Same as Multiset#min_by except that pairs of (non-duplicated) items and their counts
  # are given to the block.
  #
  # Multiset#max_by と同様ですが、ブロックには要素（重複なし）とその出現数の組が与えられます。
  def min_by_with(&block) # :yields: item, count
    tmp = @entries.each_pair.min_by(&block)
    tmp ? tmp[0] : nil # if @entries is not empty, tmp must be a two-element array
  end
  
  # Same as Multiset#minmax_by except that pairs of (non-duplicated) items and their counts
  # are given to the block.
  #
  # Multiset#minmax_by と同様ですが、ブロックには要素（重複なし）とその出現数の組が与えられます。
  def minmax_by_with(&block) # :yields: item, count
    tmp = @entries.each_pair.minmax_by(&block)
    tmp[0] ? [tmp[0][0], tmp[1][0]] : nil
  end
  
  # Generates an array by sorting the items in <code>self</code>.
  # 
  # <code>self</code>の要素を並び替えた配列を生成します。
  def sort(&block) # :yields: a, b
    ret = []
    @entries.keys.sort(&block).each do |item|
      ret.fill(item, ret.length, @entries[item])
    end
    ret
  end
  
  # The same as Multiset#sort except that, after giving the items to the block,
  # the items are sorted by the values from the block.
  # 
  # Multiset#sortと同様ですが、ブロックには1つの要素が与えられ、その値が小さいものから順に並びます。
  def sort_by(&block) # :yields: item
    ret = []
    @entries.keys.sort_by(&block).each do |item|
      ret.fill(item, ret.length, @entries[item])
    end
    ret
  end

  # Same as Multiset#sort except that the following four:
  # "item 1", "number of item 1", "item 2" and "number of item 2" are given to the block.
  #
  # Multiset#sort と同様ですが、ブロックには「要素1」「要素1の出現数」「要素2」「要素2の出現数」の
  # 4引数が与えられます。
  def sort_with # :yields: item1, count1, item2, count2
    ret = []
    @entries.each_pair.sort{ |a, b| yield(a[0], a[1], b[0], b[1]) }.each do |item_count|
      ret.fill(item_count[0], ret.length, item_count[1])
    end
    ret
  end

  # Same as Multiset#sort_by except that the pairs of (non-duplicated) items
  # and their counts are given to the block.
  # 
  # Multiset#sort_by と同様ですが、ブロックには要素（重複なし）とその出現数の組が与えられます。
  def sort_by_with # :yields: item1, count1, item2, count2
    ret = []
    @entries.each_pair.sort_by{ |a| yield(*a) }.each do |item_count|
      ret.fill(item_count[0], ret.length, item_count[1])
    end
    ret
  end
end

class Hash
  # Generates multiset from <code>self</code>.
  # Keys of the Hash are treated as items in the multiset,
  # while values of the Hash are number of items.
  # 
  # (example) <code>{:a => 4, :b => 2}.to_multiset # Multiset with four :a's and two :b's</code>
  # 
  # <code>self</code>を多重集合に変換し、その結果を返します。
  # Hashのキーを要素、Hashの値をその要素の要素数とします。
  # 
  # （例）<code>{:a => 4, :b => 2}.to_multiset # :aを4個、:bを2個含む多重集合</code>
  def to_multiset
    ret = Multiset.new
    self.each_pair{ |item, count| ret.renew_count(item, count) }
    ret
  end
end

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
