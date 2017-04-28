#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "multiset"

#==概要(Basic information)
#
# Ruby implementation of multimap.
# Unlike ordinary map, also known as associative array
# (see Ruby documentation for "Hash" class),
# multimap can contain two or more items for a key.
#
# Methods' names are basically consistent with those of Hash class.
#
# Rubyによる多重連想配列（マルチマップ）の実装です。
# 通常の連想配列（Rubyでは"Hash"クラス）と異なり、多重連想配列は
# 1つのキーに対して複数の要素が存在し得ます。
#
# メソッド名は基本的にHashクラスに合わせてあります。

class Multimap
  include Enumerable
  
  #--
  # Constructors
  #++
  
  # Generates a new multimap. Different from Hash#new , you cannot
  # specify default value.
  # 
  # 新しい多重連想配列を生成します。Hash#newと異なり、デフォルト値は
  # 設定できません。
  def initialize
    @assoc = Hash.new{ |hash, key| hash[key] = Multiset.new }
  end
  
  # Removes all keys in @assoc if the value associated with key is
  # empty multiset.
  def cleanup # :nodoc:
    @assoc.reject!{ |key, value_list| value_list.empty? }
  end
  private :cleanup
  
  # Returns values associated with <code>key</code>, which may exist
  # two or more, by the format of Multiset.
  # If <code>key</code> has not associated with any value,
  # Multimap#fetch returns empty Multiset.
  # Different from Hash#fetch, you cannot specify
  # a value or a process when <code>key</code> has not associated with
  # any value. 
  # 
  # キー<code>key</code>に対応する値（複数存在しうる）を、
  # Multisetとして返します。
  # キーに対応する値が存在しない場合、空のMultisetが返ります。
  # Hash#fetchの場合と異なり、キーに対応する値が存在しない場合の扱いを
  # 指定することはできません。
  def fetch(key)
    @assoc[key]
  end
  alias :[] :fetch
  
  # Sets values associated with <code>key</code> to <code>value_list</code>.
  # <code>value_list</code> is converted to a Multiset by Multiset.parse .
  # 
  # Returns <code>value_list</code>.
  #
  # キー<code>key</code>に対応する値（複数存在しうる）を
  # <code>value_list</code>で置き換えます。この際、
  # <code>value_list</code>はMultiset.parseを用いてMultisetに変換されます。
  # 
  # <code>value_list</code>を返します。
  def store(key, value_list)
    if value_list.class == Multiset
      @assoc[key] = value_list.dup
    else
      @assoc[key] = Multiset.parse(value_list)
    end
    value_list
  end
  alias :[]= :store
  
  # Returns whether <code>self</code> is equal to <code>other</code>.
  # 
  # <code>self</code>が<code>other</code>と等しいかどうかを返します。
  def ==(other)
    return false unless other.instance_of?(Multimap)
    @assoc == other.to_hash
  end
  
  # Converts <code>self</code> to a <code>Hash</code>
  # whose values in the Hash are all multimaps.
  #
  # <code>self</code>を<code>Hash</code>に変換して返します。
  # 返されるHash中において、値はすべてMultimap型となります。
  def to_hash
    @assoc.dup
  end
  
  # Removes all elements stored in <code>self</code>.
  # Returns <code>self</code>.
  # 
  # <code>self</code>に格納された要素をすべて削除します。
  # <code>self</code>を返します。
  def clear
    @assoc.clear
  end
  
  # Returns duplicated <code>self</code>.
  #
  # <code>self</code>の複製を生成して返します。
  def dup
    @assoc.to_multimap
  end
  
  # Replaces <code>self</code> by <code>other</code>.
  # Returns <code>self</code>.
  # 
  # <code>self</code>の内容を<code>other</code>のものに置き換えます。
  # <code>self</code>を返します。
  def replace(other)
    @assoc.clear
    other.each_pair_with do |key, a_value, count|
      @assoc[key].add a_value, count
    end
    self
  end
  
  # Deletes all values associated with <code>key</code>, and returns
  # those values as a Multiset.
  # 
  # <code>key</code>に割り当てられた全ての値を削除し、その値を
  # Multisetとして返します。
  def delete(key)
    ret = @assoc[key]
    @assoc.delete(key)
    ret
  end
  
  # Same as Multimap#delete_if except that, rather than deleting key-value pairs in
  # <code>self</code>, this generates a new Multimap with specified
  # key-value pairs are deleted.
  # 
  # Multimap#delete_ifと似ますが、<code>self</code>自身からはキーと値の組を
  # 削除せず、要素が削除された結果の多重連想配列を新たに生成して
  # 返します。
  def reject(&block) # :yields: key, single_value
    ret = self.dup
    ret.delete_if &block
    ret
  end
  
  # Gives all pairs of a key and single value in <code>self</code>
  # to given block, and deletes that element if the block returns true.
  # Returns <code>self</code>.
  #
  # ブロックに<code>self</code>のキーと値の組（値は1つ）を順次与え、
  # 結果が真であった組をすべて削除します。
  # <code>self</code>を返します。
  def delete_if(&block) # :yields: key, single_value
    cleanup
    @assoc.each_pair do |key, value_list|
      value_list.delete_if{ |single_value|
        block.call(key, single_value)
      }
    end
    self
  end
  
  # Same as Multimap#delete_if except that <code>nil</code> is returned
  # if no key-value pair is deleted.
  # 
  # Multimap#delete_ifと似ますが、キーと値の組が1つも削除されなければ
  # <code>nil</code>を返します。
  def reject!(&block) # :yields: key, single_value
    cleanup
    ret = nil
    @assoc.each_pair do |key, value_list|
      ret = self if value_list.reject!{ |single_value|
        block.call(key, single_value)
      }
    end
    ret
  end
  
  # Same as Multimap#reject except that arguments given to block is the following three:
  # (key, single value associated with the key, numbers of that value
  # associated with the key).
  # 
  # Multimap#rejectと似ますが、ブロックへの引数が（キー、キーに割り当てられた値、
  # その値がキーに割り当てられている個数）の3つの組で与えられます。
  def reject_with(&block) # :yields: key, a_value, count
    ret = self.dup
    ret.delete_with &block
    ret
  end
  
  # Same as Multimap#delete_if except that arguments given to block is the following three:
  # (key, single value associated with the key, numbers of that value
  # associated with the key).
  # 
  # Multimap#delete_ifと同じですが、ブロックへの引数が（キー、キーに割り当てられた値、
  # その値がキーに割り当てられている個数）の3つの組で与えられます。
  def delete_with(&block) # :yields: key, a_value, count
    cleanup
    @assoc.each_pair do |key, value_list|
      value_list.delete_with{ |a_value, count|
        block.call(key, a_value, count)
      }
    end
    self
  end
  
  # Iterates for each pair of a key and a value in <code>self</code>.
  # Returns <code>self</code>.
  #
  # <code>self</code>のすべてのキーと値の組について繰り返します。
  # <code>self</code>を返します。
  def each_pair
    if block_given?
      cleanup
      @assoc.each_pair do |key, value_list|
        value_list.each do |single_value|
          yield key, single_value
        end
      end
      self
    else
      Enumerator.new(self, :each_pair)
    end
  end
  alias :each :each_pair
  
  # Iterates for each pair of a key and a value in <code>self</code>,
  # giving the following three to block:
  # (key, single value associated with the key, numbers of that value
  # associated with the key). Returns <code>self</code>.
  # 
  # <code>self</code>のすべてのキーと値の組について、
  # ブロックに（キー、キーに割り当てられた値、その値が割り当てられた数）
  # の組を与えながら繰り返します。<code>self</code>を返します。
  def each_pair_with
    if block_given?
      cleanup
      @assoc.each_pair do |key, value_list|
        value_list.each_pair do |a_value, count|
          yield key, a_value, count
        end
      end
      self
    else
      Enumerator.new(self, :each_pair_with)
    end
  end
  
  # Iterates for each pair of a key and all values associated with the key
  # (list of values is given as Multiset) in <code>self</code>.
  # Returns <code>self</code>.
  # 
  # <code>self</code>のすべてのキーと、そのキーに割り当てられた
  # すべての値（Multisetで与えられる）の組について繰り返します。
  # <code>self</code>を返します。
  def each_pair_list(&block) # :yields: key, value_list
    cleanup
    @assoc.each_pair &block
  end
  
  
  # Iterates for each key in <code>self</code>. Returns <code>self</code>.
  # 
  # <code>self</code>のすべてのキーについて繰り返します。
  # <code>self</code>を返します。
  def each_key(&block) # :yields: key
    cleanup
    @assoc.each_key &block
  end
  
  # Iterates for each value in <code>self</code>. Returns <code>self</code>.
  # 
  # <code>self</code>のすべての値について繰り返します。
  # <code>self</code>を返します。
  def each_value(&block) # :yields: single_value
    if block_given?
      cleanup
      @assoc.each_value do |value_list|
        value_list.each &block
      end
      self
    else
      Enumerator.new(self, :each_value)
    end
  end
  
  # Returns an array in which keys in <code>self</code> are stored.
  # 
  # <code>self</code>のすべてのキーを、配列として返します。
  def keys
    cleanup
    @assoc.keys
  end
  
  
  # Returns a Multiset in which values in <code>self</code> are stored.
  # 
  # <code>self</code>のすべての値を、Multisetとして返します。
  def values
    cleanup
    ret = Multiset.new
    @assoc.each_value do |value_list|
      ret.merge! value_list
    end
    ret
  end
  
  # Returns whether <code>self</code> has no element.
  #
  # <code>self</code>に要素がないかどうかを返します。
  def empty?
    cleanup
    @assoc.empty?
  end
  
  # Returns whether <code>self</code> has a key <code>key</code>.
  #
  # <code>self</code>にキー<code>key</code>かあるかどうかを返します。
  def has_key?(key)
    cleanup
    @assoc.has_key?(key)
  end
  alias :key? :has_key?
  alias :include? :has_key?
  alias :member? :has_key?

  # Returns whether <code>self</code> has a value <code>value</code>.
  #
  # <code>self</code>に値<code>value</code>かあるかどうかを返します。
  def has_value?(value)
    self.values.items.include?(value)
  end
  alias :value? :has_value?
  
  # Search a pair of key and value from <code>self</code> such that
  # the value is equal to the argument <code>value</code>.
  # If two or keys are matched, returns one of them.
  # If no key is matched, returns nil.
  #
  # <code>self</code>から値が<code>value</code>であるような要素を
  # 検索し、それに対応するキーを返します。該当するキーが複数存在する場合、
  # そのうちの1つを返します。該当するキーが存在しなければ
  # <code>nil</code>を返します。
  def key(value)
    self.each_pair_with do |key, a_value, count|
      return key if value == a_value
    end
    nil
  end
  alias :index :key
  
  # Retrieves values (instances of Multiset) of <code>self</code>
  # associated with <code>key_list</code>, and returns those values
  # as an array. i.e. returns an array whose elements are multisets.
  # 
  # <code>self</code>から<code>key_list</code>の各キーに対応する値
  # （Multiset型）を取り出し、それらを配列として返します。
  # すなわち、Multisetを要素とする配列を返します。
  def values_at(*key_list)
    key_list.map{ |key| self[key] }
  end
  alias :indexes :values_at
  alias :indices :values_at
  
  # Returns a Multimap whose keys are values in <code>self</code>, and
  # values are keys in <code>self</code>. For example,
  # If <code>self</code> has a key :a associated with two :x and one :y,
  # returned multimap has two keys :x and :y, and their values are
  # two :a and one :a respectively.
  # 
  # <code>self</code>のキーと値を入れ替えたMultimapを返します。
  # 例えばキー:aに対応する値が2つの:xと1つの:yであれば、変換結果は
  # キー:xに:aが2つ、キー:yに:aが1つ対応するMultimapです。
  def invert
    ret = Multimap.new
    self.each_pair_with do |key, a_value, count|
      ret[a_value].add key, count
    end
    ret
  end
  
  # Returns number of all elements in <code>self</code>. 
  # 
  # <code>self</code>に含まれている要素数を返します。 
  def size
    ret = 0
    self.each_pair_with{ |key, a_value, count| ret += count }
    ret
  end
  alias :length :size
  
  # Add elements in <code>other</code> to <code>self</code>.
  # Returns <code>self</code>.
  # 
  # <code>self</code>に<code>other</code>の要素を追加します。
  # <code>self</code>を返します。
  def merge!(other)
    other.each_pair_with do |key, a_value, count|
      self[key].add a_value, count
    end
    self
  end
  
  # Returns merged multiset of <code>self</code> and <code>other</code>.
  #
  # <code>self</code>と<code>other</code>の要素を合わせた多重集合を返します。
  def merge(other)
    ret = self.dup
    ret.merge! other
  end
  alias :+ :merge
  
  def to_s(delim = "\n") # :nodoc:
    cleanup
    
    buf = ''
    init = true
    @assoc.each_pair do |key, value_list|
      if init
        init = false
      else
        buf += delim
      end
      buf += "#{key.inspect}=>{"
      
      init_val = true
      value_list.each_pair do |a_value, count|
        if init_val
          init_val = false
        else
          buf += ", "
        end
        buf += "\##{count} #{a_value.inspect}"
      end
      buf += "}"
    end
    buf
  end
  
  def inspect # :nodoc:
    buf = "#<Multimap:"
    buf += self.to_s(', ')
    buf += '>'
    buf
  end
end

class Hash
  # Generates multiset from <code>self</code>.
  # In generated multiset, values associated with a key are defined by
  # the result of Multiset.parse(values_in_<code>self</code>) .
  # 
  # (example)
  # Key <code>:a</code> is associated with values one <code>:x</code> and one <code>:y</code>, and 
  # key <code>:b</code> is associated with values two <code>:x</code>
  # 
  # <code>{:a => [:x, :y], :b => [:x, :x]}.to_multimap</code>
  #
  # <code>self</code>を多重連想配列に変換し、その結果を返します。
  # 新しく生成される多重連想配列においてキーに割り当てられる値は、
  # <code>self</code>におけるキーの値をMultiset.parseによって多重集合に
  # 変換したものとなります。
  # 
  # （例）キー<code>:a</code>には<code>:x</code>と<code>:y</code>が1個ずつ、
  # キー<code>:b</code>には<code>:x</code>が2個割り当てられた多重連想配列
  # 
  # <code>{:a => [:x, :y], :b => [:x, :x]}.to_multimap</code>
  def to_multimap
    ret = Multimap.new
    self.each_pair{ |key, val| ret[key] = val }
    ret
  end
  
  # Generates multiset from <code>self</code>.
  # In generated multiset, only one value is associated with a key
  # (value in <code>self</code>).
  #
  # <code>self</code>を多重連想配列に変換し、その結果を返します。
  # 新しく生成される多重連想配列においてキーに割り当てられる値は、
  # <code>self</code>に含まれる1要素のみです。
  def multimap
    ret = Multimap.new
    self.each_pair{ |key, val| ret[key] = Multiset[val] }
    ret
  end
end
