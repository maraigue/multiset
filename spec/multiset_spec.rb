require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Note: NOT ALL METHODS ARE TESTED!

require "multiset"

describe Multiset do
  # Generation methods
  describe "being generated" do
    describe "by Multiset.parse(Hash)" do
      it "should regard keys as elements and values as counts" do
        Multiset.parse({:a => 3, :b => 2}).should == Multiset[:a, :a, :a, :b, :b]
      end
    end
    
    describe "by Multiset.parse(NonHashEnumerable)" do
      it "should regard each of the elements as an element in the Multiset" do
        Multiset.parse([:a, 3, :b, 2]).should == Multiset[:a, 3, :b, 2]
      end
    end
    
    describe "by Multiset.parse(NonEnumerable)" do
      it "should be rejected" do
        lambda{ Multiset.parse(83) }.should raise_error(ArgumentError)
        lambda{ Multiset.parse("hoge\npiyo\n") }.should raise_error(ArgumentError)
      end
    end
    
    describe "by Multiset.parse_force(NonEnumerable)" do
      it "should be rejected except for strings" do
        lambda{ Multiset.parse_force(83) }.should raise_error(ArgumentError)
        Multiset.parse_force("hoge\npiyo\n").should == Multiset["hoge\n", "piyo\n"]
      end
    end
    
    describe "by Multiset#dup" do
      it "should be the same as the original Multiset" do
        tmp = Multiset.new([:a,:a,:b])
        tmp.should == tmp.dup
        
        tmp = Multiset[]
        tmp.should == tmp.dup
      end
    end
  end
  
  it "should be replaced by another Multiset by Multiset#replace" do
    tmp = Multiset[]
    tmp.replace(Multiset[:a,:b,:b]).should == Multiset[:a,:b,:b]
  end

  # Comparatory/merging methods
  describe "of two" do
    before do
      @ms1 = Multiset.new(%w'a a a a b b b c c d')
      @ms2 = Multiset.new(%w'b c c d d d e e e e')
    end
    
    it "should judge inclusions correctly" do
      tmp1 = Multiset.new(%w'a a a a b b b c c d d')
      tmp2 = Multiset.new(%w'a a a a b b b c c d')
      tmp3 = Multiset.new(%w'a a a b b b c c d')
      
      (@ms1 == @ms2).should be_false
      (@ms1 == tmp1).should be_false
      (@ms1 == tmp2).should be_true
      (@ms1 == tmp3).should be_false
      
      (@ms1.subset?(@ms2)).should be_false
      (@ms1.subset?(tmp1)).should be_true
      (@ms1.subset?(tmp2)).should be_true
      (@ms1.subset?(tmp3)).should be_false
      (@ms2.subset?(@ms1)).should be_false
      (tmp1.subset?(@ms1)).should be_false
      (tmp2.subset?(@ms1)).should be_true
      (tmp3.subset?(@ms1)).should be_true
      
      (@ms1.proper_subset?(@ms2)).should be_false
      (@ms1.proper_subset?(tmp1)).should be_true
      (@ms1.proper_subset?(tmp2)).should be_false
      (@ms1.proper_subset?(tmp3)).should be_false
      (@ms2.proper_subset?(@ms1)).should be_false
      (tmp1.proper_subset?(@ms1)).should be_false
      (tmp2.proper_subset?(@ms1)).should be_false
      (tmp3.proper_subset?(@ms1)).should be_true
      
      (@ms1.superset?(@ms2)).should be_false
      (@ms1.superset?(tmp1)).should be_false
      (@ms1.superset?(tmp2)).should be_true
      (@ms1.superset?(tmp3)).should be_true
      (@ms2.superset?(@ms1)).should be_false
      (tmp1.superset?(@ms1)).should be_true
      (tmp2.superset?(@ms1)).should be_true
      (tmp3.superset?(@ms1)).should be_false
      
      (@ms1.proper_superset?(@ms2)).should be_false
      (@ms1.proper_superset?(tmp1)).should be_false
      (@ms1.proper_superset?(tmp2)).should be_false
      (@ms1.proper_superset?(tmp3)).should be_true
      (@ms2.proper_superset?(@ms1)).should be_false
      (tmp1.proper_superset?(@ms1)).should be_true
      (tmp2.proper_superset?(@ms1)).should be_false
      (tmp3.proper_superset?(@ms1)).should be_false
    end
    
    it "should compute the intersection correctly" do
      (@ms1 & @ms2).should == Multiset.new(%w'b c c d')
    end
    
    it "should compute the union correctly" do
      (@ms1 | @ms2).should == Multiset.new(%w'a a a a b b b c c d d d e e e e')
    end
    
    it "should compute the sum correctly" do
      (@ms1 + @ms2).should == Multiset.new(%w'a a a a b b b b c c c c d d d d e e e e')
      
      tmp = @ms1.dup
      tmp.merge!(@ms2)
      tmp.should == Multiset.new(%w'a a a a b b b b c c c c d d d d e e e e')
    end
    
    it "should compute the difference correctly" do
      (@ms1 - @ms2).should == Multiset.new(%w'a a a a b b')
      
      tmp = @ms1.dup
      tmp.subtract!(@ms2)
      tmp.should == Multiset.new(%w'a a a a b b')
    end
  end
  
  # Iteration methods
  describe "being iterated for entries" do
    before do
      @ms = Multiset.new(%w'a a b b b b c d d d')
    end
    
    it "should have the same result between Multiset\#{all?, any?, none?, one?} and Enumerable\#{all?, any?, none?, one?}" do
      @ms.all?{ |x| x == "a" }.should be_false
      @ms.any?{ |x| x == "a" }.should be_true
      @ms.none?{ |x| x == "a" }.should be_false
      @ms.none?{ |x| x.instance_of?(Integer) }.should be_true
      @ms.one?{ |x| x == "a" }.should be_false
      @ms.one?{ |x| x == "c" }.should be_true
    end
    
    it "should have the same result between Multiset#count and Enumerable#count" do
      @ms.count("a").should == 2
      @ms.count("x").should == 0
      @ms.count.should == 10
      @ms.count{ |x| x == "b" }.should == 4
    end
    
    it "should find an items by the specified condition with Multiset#find / Multiset#detect" do
      @ms.find{ |item| item =~ /d/ }.should == "d"
    end
    
    it "should find an item by the specified condition with Multiset#find_with / Multiset#detect_with" do
      @ms.find_with{ |item, count| count == 2 }.should == "a"
    end
    
    it "should find an items by the specified condition with Multiset#find_all / Multiset#select" do
      @ms.find_all{ |item| item =~ /d/ }.should == Multiset.new(%w[d d d])
    end
    
    it "should find an items by the specified condition with Multiset#find_all_with / Multiset#select_with" do
      @ms.find_all_with{ |item, count| count <= 2 }.should == Multiset.new(%w[a a c])
    end
    
    it "should find an items by the specified condition with Multiset#reject" do
      @ms.reject{ |item| item =~ /d/ }.should == Multiset.new(%w[a a b b b b c])
    end
    
    it "should find an items by the specified condition with Multiset#reject!" do
      @ms.reject!{ |item| item =~ /x/ }.should be_nil
      @ms.reject!{ |item| item =~ /d/ }.object_id.should == @ms.object_id
      @ms.should == Multiset.new(%w[a a b b b b c])
    end
    
    it "should find an items by the specified condition with Multiset#delete_if" do
      @ms.delete_if{ |item| item =~ /x/ }.object_id.should == @ms.object_id
      @ms.delete_if{ |item| item =~ /d/ }.object_id.should == @ms.object_id
      @ms.should == Multiset.new(%w[a a b b b b c])
    end
    
    it "should find an items by the specified condition with Multiset#reject_with" do
      @ms.reject_with{ |item, count| item =~ /d/ || count > 3 }.should == Multiset.new(%w[a a c])
    end
    
    it "should find an items by the specified condition with Multiset#grep" do
      @ms.grep(/d/).should == Multiset.new(%w[d d d])
      @ms.grep(/d/){ |item| item + "x" }.should == Multiset.new(%w[dx dx dx])
    end
    
    it "should repeat for items by the specified condition with Multiset#inject_with / Multiset#reduce_with" do
      result = @ms.inject_with({ :item_sum => "", :count_sum => 0 }) do |obj, item, count|
        obj[:item_sum] += item
        obj[:count_sum] += count
        obj
      end
      result[:item_sum].each_char.sort.should == %w[a b c d]
      result[:count_sum].should == 10
    end
    
    it "should return an Enumerator with Multiset#each_****" do
      @ms.each.should be_kind_of(Enumerator)
      @ms.each_item.should be_kind_of(Enumerator)
      @ms.each_pair.should be_kind_of(Enumerator)
      @ms.each_with_count.should be_kind_of(Enumerator)
    end
    
    it "should return an Enumerator with Multiset#each_**** whose behavior is the same as original method" do
      e = @ms.each
      e.to_a.should == @ms.to_a
      
      e = @ms.each_item
      a = []; @ms.each_item{ |x| a << x }
      b = []; e.each{ |x| b << x }
      b.should == a
      
      e = @ms.each_with_count
      a = []; @ms.each_with_count{ |x, i| a << [x, i] }
      b = []; e.each{ |x, i| b << [x, i] }
      b.should == a
    end
    
    it "should return a new Multiset by the specified condition with Multiset#map / Multiset#collect" do
      @ms.map{ |item| item * 2 }.should == Multiset.new(%w'aa aa bb bb bb bb cc dd dd dd')
    end
    
    it "should return a new Multiset by the specified condition with Multiset#map_with / Multiset#collect_with" do
      @ms.map_with{ |item, count| [item * 2, count * 2] }.should == Multiset.new(%w'aa aa aa aa bb bb bb bb bb bb bb bb cc cc dd dd dd dd dd dd')
    end

    it "should return nil for an empty Multiset with Multiset#rand" do
      Multiset.new.rand.should == nil
    end

    it "should return the maximum/mininum value by max/min/minmax" do
      @ms.max.should == "d"
      @ms.min.should == "a"
      @ms.minmax.should == %w[a d]
      @ms.max{ |a, b| b <=> a }.should == "a"
      @ms.min{ |a, b| b <=> a }.should == "d"
      @ms.minmax{ |a, b| b <=> a }.should == %w[d a]
    end
    
    it "should return the maximum/mininum value by max_by/min_by/minmax_by" do
      @ms.max_by{ |item| item }.should == "d"
      @ms.min_by{ |item| item }.should == "a"
      @ms.minmax_by{ |item| item }.should == %w[a d]
    end
    
    it "should return the maximum/mininum value by max_with/min_with/minmax_with" do
      @ms.max_with{ |a_item, a_count, b_item, b_count| a_count <=> b_count }.should == "b"
      @ms.max_with{ |a_item, a_count, b_item, b_count| b_count <=> a_count }.should == "c"
      @ms.min_with{ |a_item, a_count, b_item, b_count| a_count <=> b_count }.should == "c"
      @ms.min_with{ |a_item, a_count, b_item, b_count| b_count <=> a_count }.should == "b"
      @ms.minmax_with{ |a_item, a_count, b_item, b_count| a_count <=> b_count }.should == %w[c b]
    end
    
    it "should return the maximum/mininum value by max_by_with/min_by_with/minmax_by_with" do
      @ms.max_by_with{ |item, count| count }.should == "b"
      @ms.min_by_with{ |item, count| count }.should == "c"
      @ms.minmax_by_with{ |item, count| count }.should == %w[c b]
    end
    
    it "should return sorted array by Multiset#sort / Multiset#sort_with" do
      @ms.sort.should == %w[a a b b b b c d d d]
      @ms.sort{ |a, b| b <=> a }.should == %w[d d d c b b b b a a]
      @ms.sort_with{ |a_item, a_count, b_item, b_count| b_count <=> a_count }.should == %w[b b b b d d d a a c]
    end
    
    it "should return sorted array by Multiset#sort_by / Multiset#sort_by_with" do
      @ms.sort_by{ |item| item }.should == %w[a a b b b b c d d d]
      @ms.sort_by_with{ |item, count| count }.should == %w[c a a d d d b b b b]
    end
  end

  # Updating methods
  describe "being updated" do
    before do
      @ms1 = Multiset.new(%w'a a a a b b b c c d')
    end
    
    it "should add an element correctly" do
      tmp = @ms1.dup
      tmp << "a"
      tmp.should == Multiset.new(%w'a a a a a b b b c c d')
    end
    
    it "should add multiple element correctly" do
      tmp = @ms1.dup
      tmp.add("e", 3)
      tmp.should == Multiset.new(%w'a a a a b b b c c d e e e')
      
      tmp = @ms1.dup
      tmp.add("a", 3)
      tmp.should == Multiset.new(%w'a a a a a a a b b b c c d')
    end
    
    it "should remove an element correctly" do
      tmp = @ms1.dup
      tmp.delete("a")
      tmp.should == Multiset.new(%w'a a a b b b c c d')
      
      tmp = @ms1.dup
      tmp.delete("e") # nothing deleted because `tmp' does not contain "e"
      tmp.should == @ms1
    end
    
    it "should remove multiple element correctly" do
      tmp = @ms1.dup
      tmp.delete("a", 3)
      tmp.should == Multiset.new(%w'a b b b c c d')
      
      tmp = @ms1.dup
      tmp.delete("a", 6) # in case `tmp' does not contain "a" less than 6 times
      tmp.should == Multiset.new(%w'b b b c c d')
    end
    
    it "should remove all element of specified value correctly" do
      tmp = @ms1.dup
      tmp.delete_all("a")
      tmp.should == Multiset.new(%w'b b b c c d')
      
      tmp = @ms1.dup
      tmp.delete_all("e") # nothing deleted because ``tmp'' does not contain "e"
      tmp.should == @ms1
    end
  end
end

describe Hash, "when converted to a multiset" do
  it "should regard keys as elements and values as counts by Hash#to_multiset" do
    {:a => 2, :b => 1}.to_multiset.should == Multiset[:a,:a,:b]
    {:x => 2, :y => 2, :z => 0}.to_multiset.should == Multiset[:x,:x,:y,:y]
  end
end

describe Multimap do
  describe "generated by adding items one by one" do
    before do
      @empty_multiset = Multiset.new
      @mm = Multimap.new
    end
    
    it "should be empty for any key when generated without parameters" do
      @mm[:a].should == @empty_multiset
      @mm[:b].should == @empty_multiset
    end
    
    it "should be a singleton multiset by adding a scalar value" do
      @mm[:a].add "bar"
      @mm[:a].should == Multiset["bar"]
    end
    
    it "should not make any unsolicited change" do
      @mm[:a].add "bar"
      @mm[:b].should == @empty_multiset
    end
    
    it "should be a multiset constructed by the given array" do
      @mm[:a] = %w[foo foo bar]
      @mm[:a].should == Multiset.new(%w[foo foo bar])
    end
    
    it "should be a multiset constructed by the given hash (key: element, value: count)" do
      @mm[:a] = {"foo" => 3, "bar" => 2}
      @mm[:a].should == Multiset["foo", "foo", "bar", "foo", "bar"]
    end
    
    it "should not be updated by setting a scalar (other than 'Enumerable' object)" do
      lambda{ @mm[:a] = "foobar" }.should raise_error(ArgumentError)
      lambda{ @mm[:a] = 56 }.should raise_error(ArgumentError)
    end
  
    it "should be duplicated by Multimap#dup" do
      @mm.dup.should == @mm
    end
  end

  describe "being compared" do
    it "should be correctly compared" do
      mm1 = Multimap.new
      mm1[:a] = ["foo", "foo", "bar", "hoge", "hoge", "moe"]
      mm1[:b] = ["foo", "bar", "hoge", "hoge", "bar"]
      mm2 = Multimap.new
      mm2[:a] = ["foo", "foo", "bar", "hoge", "hoge", "moe"]
      mm2[:b] = ["foo", "bar", "hoge", "hoge", "bar"]
      mm3 = Multimap.new
      mm3[:a] = ["foo", "foo", "bar", "hoge", "hoge", "moe"]
      mm3[:b] = ["foo", "bar", "hoge", "hoge", "bar", "buz"]
      
      mm1.should == mm2
      mm1.should_not == mm3
      
      mm3.dup.should == mm3
    end
    
    it "should be correctly decided whether it is empty or not" do
      mm = Multimap.new
      
      mm[:a] = []
      mm[:b] = [:a, :b]
      mm.should_not be_empty
      
      mm[:a] = []
      mm[:b] = []
      mm.should be_empty
    end
  end
  
  describe "being referred" do
    before do
      @mm = Multimap.new
      @mm[:a] = ["foo", "foo", "bar", "hoge", "hoge", "moe"]
      @mm[:b] = ["foo", "bar", "hoge", "hoge", "bar"]
    end
    
    it "should return an Enumerator with Multimap#each_****" do
      @mm.each.should be_kind_of(Enumerator)
      @mm.each_pair.should be_kind_of(Enumerator)
      @mm.each_key.should be_kind_of(Enumerator)
      @mm.each_value.should be_kind_of(Enumerator)
      @mm.each_pair_list.should be_kind_of(Enumerator)
      @mm.each_pair_with.should be_kind_of(Enumerator)
    end
    
    it "should return an Enumerator with Multimap#each_**** whose behavior is the same as original method" do
      e = @mm.each_key
      a = []; @mm.each_key{ |k| a << k }
      b = []; e.each{ |k| b << k }
      b.should == a
      
      e = @mm.each_value
      a = []; @mm.each_value{ |v| a << v }
      b = []; e.each{ |v| b << v }
      b.should == a
      
      e = @mm.each_pair_list
      a = []; @mm.each_pair_list{ |k, v| a << [k, v] }
      b = []; e.each{ |k, v| b << [k, v] }
      b.should == a
      
      e = @mm.each_pair_with
      a = []; @mm.each_pair_with{ |k, v, c| a << [k, v, c] }
      b = []; e.each{ |k, v, c| b << [k, v, c] }
      b.should == a
    end
    
    it "should be correctly iterated by 'each_pair'" do
      tmp_a = []
      tmp_b = []
      @mm.each_pair do |key, sval|
        case key
        when :a
          tmp_a << sval
        when :b
          tmp_b << sval
        else
          raise
        end
      end
      tmp_a.sort.should == ["foo", "foo", "bar", "hoge", "hoge", "moe"].sort
      tmp_b.sort.should == ["foo", "bar", "hoge", "hoge", "bar"].sort
    end
    
    it "should be correctly iterated by 'each_pair_with'" do
      tmp_a = []
      tmp_b = []
      @mm.each_pair_with do |key, val, cnt|
        case key
        when :a
          tmp_a << val
        when :b
          tmp_b << val
        else
          raise
        end
      end
      tmp_a.sort.should == ["foo", "foo", "bar", "hoge", "hoge", "moe"].uniq.sort
      tmp_b.sort.should == ["foo", "bar", "hoge", "hoge", "bar"].uniq.sort
    end
    
    it "should be correctly iterated by 'each_pair_list'" do
      flag = 0
      @mm.each_pair_list do |key, vals|
        case key
        when :a
          vals.should == Multiset["foo", "foo", "bar", "hoge", "hoge", "moe"]
          flag += 1
        when :b
          vals.should == Multiset["foo", "bar", "hoge", "hoge", "bar"]
          flag += 1
        else
          raise
        end
      end
      flag.should == 2
    end
    
    it "should ignore non-existent key by 'each_key'" do
      @mm[:c] = []
      
      ms = Multiset.new
      @mm.each_key{ |key| ms << key }
      ms.should == Multiset[:a, :b]
    end
    
    it "should be correctly iterated by 'each_value'" do
      ms = Multiset.new
      @mm.each_value{ |sval| ms << sval }
      ms.should == {"foo" => 3, "bar" => 3, "hoge" => 4, "moe" => 1}.to_multiset
    end
  end
  
  describe "being updated" do
    before do
      @mm = Multimap.new
      @mm[:a] = ["foo", "foo", "bar", "hoge", "hoge", "moe"]
      @mm[:b] = ["foo", "bar", "hoge", "hoge", "bar"]
    end
    
    it "should release items when 'delete'd" do
      @mm.delete(:a).should == Multiset["foo", "foo", "bar", "hoge", "hoge", "moe"]
      @mm[:a].should == Multiset[]
      @mm[:b].should == Multiset["foo", "bar", "hoge", "hoge", "bar"]
    end
    
    it "should not release items when 'reject'ed ('reject'ed from only return value)" do
      mm1 = @mm.reject{ |key, sval| sval =~ /o/ }
      
      mm1[:a].should == Multiset["bar"]
      mm1[:b].should == Multiset["bar", "bar"]
      mm1.should_not == @mm
    end
    
    it "should equal to 'reject!'ed multimap when 'delete_if' is applied" do
      mm1 = @mm.dup
      mm2 = @mm.dup
      
      mm1.delete_if{ |key, sval| sval =~ /o/ }
      mm2.reject!{ |key, sval| sval =~ /o/ }
      mm1.should == mm2
      
      mm1.delete_if{ |key, sval| sval =~ /x/ }
      mm2.reject!{ |key, sval| sval =~ /x/ }
      mm1.should == mm2
    end
    
    it "should return nil when 'reject!' rejects nothing but 'delete_if' not" do
      mm1 = @mm.dup
      mm2 = @mm.dup
      
      mm1.delete_if{ |key, sval| sval =~ /o/ }.should == mm1
      mm2.reject!{ |key, sval| sval =~ /o/ }.should == mm2
      
      mm1.delete_if{ |key, sval| sval =~ /x/ }.should == mm1
      mm2.reject!{ |key, sval| sval =~ /x/ }.should == nil
    end
    
    it "should not release items when 'reject_with' is applied ('reject'ed from only return value)" do
      # reject_with
      mm1 = @mm.reject_with{ |key, val, cnt| cnt >= 2 }
      
      mm1[:a].should == Multiset["bar", "moe"]
      mm1[:b].should == Multiset["foo"]
      mm1.should_not == @mm
    end
    
    it "should release items when 'delete_with' is applied" do
      retval = @mm.delete_with{ |key, val, cnt| cnt >= 2 }
      retval.should == @mm
      @mm[:a].should == Multiset["bar", "moe"]
      @mm[:b].should == Multiset["foo"]
    end
    
    it "should release items when 'delete_with' is applied (but not deleted anything)" do
      retval = @mm.delete_with{ |key, val, cnt| cnt >= 2 && val.length > 4 }
      retval.should == @mm
      @mm[:a].should == Multiset["foo", "foo", "bar", "hoge", "hoge", "moe"]
      @mm[:b].should == Multiset["foo", "bar", "hoge", "hoge", "bar"]
    end
  end

  describe "being checked its properties" do
    before do
      @mm_base = Multimap.new
      @mm_base[:a] = ["foo", "foo", "bar", "hoge", "hoge", "moe"]
      @mm_base[:b] = ["foo", "bar", "hoge", "hoge", "bar"]
    end
    
    # keys, values
    it "should return existing (nonzero) keys by Multimap#keys" do
      mm = @mm_base.dup
      mm[:c] = []
      mm.keys.should satisfy{ |ks| ks == [:a, :b] || ks == [:b, :a] }
    end
    
    it "should return all values by Multimap#values" do
      @mm_base.values.should == {"foo" => 3, "bar" => 3, "hoge" => 4, "moe" => 1}.to_multiset
    end
    
    # empty?
    it "should return true by Multimap#empty? if and only if it is empty" do
      mm = @mm_base.dup
      mm[:a] = []
      mm.delete :b
      mm.should be_empty
      
      mm[:c] = [:x]
      mm.should_not be_empty
    end
    
    # has_key?
    it "should return true by Multimap#has_key? if and only if it has the given key" do
      mm = @mm_base.dup
      mm[:c] = []
      mm[:d] = [:z]
      mm.should have_key(:a)
      mm.should have_key(:b)
      mm.should_not have_key(:c)
      mm.should be_member(:d)
      mm.should_not be_member(:x)
    end
    
    # has_value?
    it "should return true by Multimap#has_value? if and only if it has the given value" do
      mm = @mm_base.dup
      mm[:c] = []
      mm[:d] = [:z]
      mm.should have_value("foo")
      mm.should have_value(:z)
      mm.should_not have_value("boo")
      mm.should be_value("hoge")
      mm.should_not be_value(:d)
    end
    
    # index
    it "should find a value and return a key by Multimap#index" do
      mm = @mm_base.dup
      mm.index("moe").should == :a
      [:a, :b].should be_member(mm.index("hoge"))
      mm.index("boo").should == nil
    end
    
    # values_at
    it "should find a corresponding values as multisets by Multimap#values_at" do
      mm = @mm_base.dup
      mm[:x] = []
      
      mm.values_at(:b, :x, :a).should == [
        Multiset["foo", "bar", "hoge", "hoge", "bar"],
        Multiset[],
        Multiset["foo", "foo", "bar", "hoge", "hoge", "moe"],
      ]
      
      mm.indexes(:b, :x, :a).should == mm.values_at(:b, :x, :a)
    end
    
    # length, size
    it "should return the collect number of entries by Multimap#length/size" do
      mm = @mm_base.dup
      mm.length.should == 11
      mm[:c] = [:y]
      mm.length.should == 12
      mm.length.should == mm.size
    end
  end
end

describe Hash, "when converted to a multimap" do
  it "should regard keys as multimap keys and values as multisets by Hash#to_multimap" do
    # to_multimap / multimap
    mm = {:a => [3, 3], :b => [5, 3]}.to_multimap
    mm[:a].should == Multiset[3, 3]
    mm[:b].should == Multiset[5, 3]
  end
  
  it "should regard keys as multimap keys and values as multisets by Hash#multimap" do
    mm = {:a => [3, 3], :b => [5, 3]}.multimap
    mm[:a].should == Multiset[[3, 3]]
    mm[:b].should == Multiset[[5, 3]]
  end
end

