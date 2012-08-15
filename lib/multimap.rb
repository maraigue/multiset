#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "multiset"

#==概要(Basic information)
#
#Rubyによる多重連想配列（マルチマップ）の実装です。
#通常の連想配列（Rubyでは"Hash"クラス）と異なり、多重連想配列は
#1つのキーに対して複数の要素が存在し得ます。
#
#メソッド名は基本的にHashクラスに合わせてあります。またHashクラスが持つ
#メソッドの大部分を実装していますが、いくつか未実装なものもあります。
#
#Ruby implementation of multimap.
#Unlike ordinary map, also known as associative array
#(see Ruby documentation for "Hash" class),
#multimap can contain two or more items for a key.
#
#Most methods' names are same as those of Hash class, and all other than
#a few methods in Hash class is implemented on Multimap class.

class Multimap
  include Enumerable
  
  #--
  # Constructors
  #++
  
  # 新しい多重連想配列を生成します。Hash#newと異なり、デフォルト値は
  # 設定できません。
  # 
  # Generates a new multimap. Different from Hash#new , you can not
  # specify default value.
  def initialize
    @assoc = Hash.new{ |hash, key| hash[key] = Multiset.new }
  end
  
  # Removes all keys in @assoc if the value associated with key is
  # empty multiset.
  def cleanup # :nodoc:
    @assoc.reject!{ |key, value_list| value_list.empty? }
  end
  private :cleanup
  
  # キー<code>key</code>に対応する値（複数存在しうる）を、
  # Multisetとして返します。Hash#fetchの場合と異なり、キーに対応する
  # 値が存在しない場合の扱いを指定することはできません。
  # （そのような場合、空のMultisetが返ります。）
  # 
  # Returns values associated with <code>key</code> with format of
  # Multiset. Different from Hash#fetch, you can not specify
  # a value or a process when <code>key</code> has not associated with
  # any value. If <code>key</code> has not associated with any value,
  # Multimap#fetch returns empty Multiset.
  def fetch(key)
    @assoc[key]
  end
  alias :[] :fetch
  
  # キー<code>key</code>に対応する値（複数存在しうる）を
  # <code>value_list</code>で置き換えます。この際、
  # <code>value_list</code>はMultiset.parseを用いてMultisetに変換されます。
  # 
  # <code>value_list</code>を返します。
  # 
  # Sets values associated with <code>key</code> to <code>value_list</code>.
  # <code>value_list</code> is converted to a Multiset by Multiset.parse .
  # 
  # Returns <code>value_list</code>.
  def store(key, value_list)
    if value_list.class == Multiset
      @assoc[key] = value_list.dup
    else
      @assoc[key] = Multiset.parse(value_list)
    end
    value_list
  end
  alias :[]= :store
  
  # <code>self</code>が<code>other</code>と等しいかどうかを返します。
  # 
  # Returns whether <code>self</code> is equal to <code>other</code>.
  def ==(other)
    return false unless other.instance_of?(Multimap)
    @assoc == other.to_hash
  end
  
  # <code>self</code>を<code>Hash</code>に変換して返します。
  # 生成されるハッシュの構造については、Hash#to_multimapをご覧下さい。
  # その際、返されるハッシュにおいて値はすべてMultimap型となります。
  #
  # Converts <code>self</code> to a <code>Hash</code>.
  # See Hash#to_multimap about format of generated hash.
  # All values in the returned hash are multimaps.
  def to_hash
    @assoc.dup
  end
  
  # <code>self</code>に格納された要素をすべて削除します。
  # <code>self</code>を返します。
  # 
  # Removes all elements stored in <code>self</code>.
  # Returns <code>self</code>.
  def clear
    @assoc.clear
  end
  
  # <code>self</code>の複製を生成して返します。
  #
  # Returns duplicated <code>self</code>.
  def dup
    @assoc.to_multimap
  end
  
  # <code>self</code>の内容を<code>other</code>のものに置き換えます。
  # <code>self</code>を返します。
  # 
  # Replaces <code>self</code> by <code>other</code>.
  # Returns <code>self</code>.
  def replace(other)
    @assoc.clear
    other.each_pair_with do |key, a_value, count|
      @assoc[key].add a_value, count
    end
    self
  end
  
  # <code>key</code>に割り当てられた全ての値を削除し、その値を
  # Multisetとして返します。
  # 
  # Deletes all values associated with <code>key</code>, and returns
  # those values as a Multiset.
  def delete(key)
    ret = @assoc[key]
    @assoc.delete(key)
    ret
  end
  
  # delete_ifと同じですが、<code>self</code>自身からはキーと値の組を
  # 削除せず、要素が削除された結果の多重連想配列を新たに生成して
  # 返します。
  # 
  # Same as delete_if, but generates a new Multimap whose pairs of
  # key and value are deleted, instead of deleting pairs in
  # <code>self</code>.
  def reject(&block) # :yields: key, single_value
    ret = self.dup
    ret.delete_if &block
    ret
  end
  
  # ブロックに<code>self</code>のキーと値の組（値は1つ）を順次与え、
  # 結果が真であった組をすべて削除します。
  # <code>self</code>を返します。
  #
  # Gives all pairs of a key and single value in <code>self</code>
  # to given block, and deletes that element if the block returns true.
  # Returns <code>self</code>.
  def delete_if(&block) # :yields: key, single_value
    cleanup
    @assoc.each_pair do |key, value_list|
      value_list.delete_if{ |single_value|
        block.call(key, single_value)
      }
    end
    self
  end
  
  # delete_ifと同じですが、キーと値の組が1つも削除されなければ
  # <code>nil</code>を返します。
  # 
  # Same as delete_if, but returns <code>nil</code> if no pair of
  # key and value is deleted.
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
  
  # rejectと同じですが、ブロックへの引数が（キー、キーに割り当てられた値、
  # その値がキーに割り当てられている個数）の3つの組で与えられます。
  # 
  # Same as reject, but arguments given to block is the tuple of three:
  # (key, one value associated with the key, numbers of that value
  # associated with the key).
  def reject_with(&block) # :yields: key, a_value, count
    ret = self.dup
    ret.delete_with &block
    ret
  end
  
  # delete_ifと同じですが、ブロックへの引数が（キー、キーに割り当てられた値、
  # その値がキーに割り当てられている個数）の3つの組で与えられます。
  # 
  # Same as delete_if, but arguments given to block is the tuple of three:
  # (key, one value associated with the key, numbers of that value
  # associated with the key).
  def delete_with(&block) # :yields: key, a_value, count
    cleanup
    @assoc.each_pair do |key, value_list|
      value_list.delete_with{ |a_value, count|
        block.call(key, a_value, count)
      }
    end
    self
  end
  
  # <code>self</code>のすべてのキーと値の組について繰り返します。
  # <code>self</code>を返します。
  # 
  # Iterates for each pair of a key and a value in <code>self</code>.
  # Returns <code>self</code>.
  def each_pair
    cleanup
    @assoc.each_pair do |key, value_list|
      value_list.each do |single_value|
        yield key, single_value
      end
    end
    self
  end
  alias :each :each_pair
  
  # <code>self</code>のすべてのキーと値の組について、
  # ブロックに（キー、キーに割り当てられた値、その値が割り当てられた数）
  # の組を与えながら繰り返します。<code>self</code>を返します。
  # 
  # Iterates for each pair of a key and a value in <code>self</code>,
  # giving the tuple of three to block:
  # (key, one value associated with the key, numbers of that value
  # associated with the key). Returns <code>self</code>.
  def each_pair_with
    cleanup
    @assoc.each_pair do |key, value_list|
      value_list.each_pair do |a_value, count|
        yield key, a_value, count
      end
    end
    self
  end
  
  # <code>self</code>のすべてのキーと、そのキーに割り当てられた
  # すべての値（Multisetで与えられる）の組について繰り返します。
  # <code>self</code>を返します。
  # 
  # Iterates for each pair of a key and all values associated with the key
  # (list of values is given as Multiset) in <code>self</code>.
  # Returns <code>self</code>.
  def each_pair_list(&block) # :yields: key, value_list
    cleanup
    @assoc.each_pair &block
  end
  
  
  # <code>self</code>のすべてのキーについて繰り返します。
  # <code>self</code>を返します。
  # 
  # Iterates for each key in <code>self</code>. Returns <code>self</code>.
  def each_key(&block) # :yields: key
    cleanup
    @assoc.each_key &block
  end
  
  # <code>self</code>のすべての値について繰り返します。
  # <code>self</code>を返します。
  # 
  # Iterates for each value in <code>self</code>. Returns <code>self</code>.
  def each_value(&block) # :yields: single_value
    cleanup
    @assoc.each_value do |value_list|
      value_list.each &block
    end
  end
  
  # <code>self</code>のすべてのキーを、配列として返します。
  # 
  # Returns an array in which keys in <code>self</code> are stored.
  def keys
    cleanup
    @assoc.keys
  end
  
  
  # <code>self</code>のすべての値を、Multisetとして返します。
  # 
  # Returns a Multiset in which values in <code>self</code> are stored.
  def values
    cleanup
    ret = Multiset.new
    @assoc.each_value do |value_list|
      ret.merge! value_list
    end
    ret
  end
  
  # <code>self</code>に要素がないかどうかを返します。
  #
  # Returns whether <code>self</code> has no element.
  def empty?
    cleanup
    @assoc.empty?
  end
  
  # <code>self</code>にキー<code>key</code>かあるかどうかを返します。
  #
  # Returns whether <code>self</code> has a key <code>key</code>.
  def has_key?(key)
    cleanup
    @assoc.has_key?(key)
  end
  alias :key? :has_key?
  alias :include? :has_key?
  alias :member? :has_key?

  # <code>self</code>に値<code>value</code>かあるかどうかを返します。
  #
  # Returns whether <code>self</code> has a value <code>value</code>.
  def has_value?(value)
    self.values.items.include?(value)
  end
  alias :value? :has_value?
  
  # <code>self</code>から値が<code>value</code>であるような要素を
  # 検索し、それに対応するキーを返します。該当するキーが複数存在する場合、
  # そのうちの1つを返します。該当するキーが存在しなければ
  # <code>nil</code>を返します。
  #
  # Search a pair of key and value from <code>self</code> such that
  # the value is equal to the argument <code>value</code>.
  # If two or keys are matched, returns one of them.
  # If no key is matched, returns nil.
  def key(value)
    self.each_pair_with do |key, a_value, count|
      return key if value == a_value
    end
    nil
  end
  alias :index :key
  
  # <code>self</code>から<code>key_list</code>の各キーに対応する値
  # （Multiset型）を取り出し、それらを配列として返します。
  # すなわち、Multisetを要素とする配列を返します。
  # 
  # Gets values (instances of Multiset) of <code>self</code>
  # associated with <code>key_list</code>, and returns those values
  # as an array. i.e. returns an array whose elements are multisets.
  def values_at(*key_list)
    key_list.map{ |key| self[key] }
  end
  alias :indexes :values_at
  alias :indices :values_at
  
  # <code>self</code>のキーと値を入れ替えたMultimapを返します。
  # 例えばキー:aに対応する値が2つの:xと1つの:yであれば、変換結果は
  # キー:xに:aが2つ、キー:yに:aが1つ対応するMultimapです。
  # 
  # Returns a Multimap whose keys are values in <code>self</code>, and
  # values are keys in <code>self</code>. For example,
  # If <code>self</code> has a key :a associated with two :x and one :y,
  # returned multimap has two keys :x and :y, and their values are
  # two :a and one :a respectively.
  def invert
    ret = Multimap.new
    self.each_pair_with do |key, a_value, count|
      ret[a_value].add key, count
    end
    ret
  end
  
  # <code>self</code>に含まれている要素数を返します。 
  # 
  # Returns number of all elements in <code>self</code>. 
  def size
    ret = 0
    self.each_pair_with{ |key, a_value, count| ret += count }
    ret
  end
  alias :length :size
  
  # <code>self</code>に<code>other</code>の要素を追加します。
  # <code>self</code>を返します。
  # 
  # Add elements in <code>other</code> to <code>self</code>.
  # Returns <code>self</code>.
  def merge!(other)
    other.each_pair_with do |key, a_value, count|
      self[key].add a_value, count
    end
    self
  end
  
  # <code>self</code>と<code>other</code>の要素を合わせた多重集合を返します。
  #
  # Returns merged multiset of <code>self</code> and <code>other</code>.
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
  # <code>self</code>を多重連想配列に変換し、その結果を返します。
  # 新しく生成される多重連想配列においてキーに割り当てられる値は、
  # <code>self</code>におけるキーの値をMultiset.parseによって多重集合に
  # 変換したものとなります。
  # 
  # （例）キー<code>:a</code>には<code>:x</code>と<code>:y</code>が1個ずつ、
  # キー<code>:b</code>には<code>:x</code>が2個割り当てられた多重連想配列
  # 
  # <code>{:a => [:x, :y], :b => [:x, :x]}.to_multiset</code>
  # 
  # Generates multiset from <code>self</code>.
  # In generated multiset, values associated with a key are defined by
  # the result of Multiset.parse(values_in_<code>self</code>) .
  # 
  # (example)
  # Key <code>:a</code> is associated with values one <code>:x</code> and one <code>:y</code>, and 
  # key <code>:b</code> is associated with values two <code>:x</code>
  # 
  # <code>{:a => [:x, :y], :b => [:x, :x]}.to_multiset</code>
  def to_multimap
    ret = Multimap.new
    self.each_pair{ |key, val| ret[key] = val }
    ret
  end
  
  # <code>self</code>を多重連想配列に変換し、その結果を返します。
  # 新しく生成される多重連想配列においてキーに割り当てられる値は、
  # <code>self</code>に含まれる1要素のみです。
  # 
  # Generates multiset from <code>self</code>.
  # In generated multiset, only one value is associated with a key
  # (value in <code>self</code>).
  def multimap
    ret = Multimap.new
    self.each_pair{ |key, val| ret[key] = Multiset[val] }
    ret
  end
end
