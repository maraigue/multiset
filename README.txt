= multiset

* http://maraigue.hhiro.net/multiset/

Ruby implementation of the multiset

== DESCRIPTION:

Unlike ordinary set(see Ruby documentation for "set" library), multiset can contain two or more same items.

 Set[:a,:b,:c,:b,:b,:c] # => #<Set: {:b, :c, :a}>
 Multiset[:a,:b,:c,:b,:b,:c] # => #<Multiset:#3 :b, #2 :c, #1 :a>

Multisets are typically used for counting elements and their appearances in collections. 

== FEATURES/PROBLEMS:

* Nothing for now

== SYNOPSIS:

 # Creating a multiset
 Set[:a,:b,:c,:b,:b,:c] # => #<Set: {:b, :c, :a}>
 Multiset[:a,:b,:c,:b,:b,:c] # => #<Multiset:#3 :b, #2 :c, #1 :a>
 
 # Counting the appearances of characters in a string
 m = Multiset.new
 "abracadabra".each_char do |c| # replace with 'each_byte' in Ruby 1.8.6 or earlier
   m << c
 end
 p m
 # => #<Multiset:#5 "a", #2 "b", #2 "r", #1 "c", #1 "d">
 
 # The same
 Multiset.new("abracadabra".split(//))
 # => #<Multiset:#5 "a", #2 "b", #2 "r", #1 "c", #1 "d">
 
 # The same, but available with Ruby 1.8.7 or later
 Multiset.new("abracadabra".each_char)
 # => #<Multiset:#5 "a", #2 "b", #2 "r", #1 "c", #1 "d">

See also: http://maraigue.hhiro.net/multiset/reverseref.en.html

== REQUIREMENTS:

No specific external libraries/tools are required.

== INSTALL:

gem install multiset

== DEVELOPERS:

After checking out the source, run:

  $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

== LICENSE:

(The MIT License)

Copyright (c) 2008-2014 H.Hiro (Maraigue)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
