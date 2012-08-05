#!/usr/bin/env ruby

VERSION = "0.4.0"

#Rubyによる多重集合（マルチセット）・多重連想配列（マルチマップ）の実装です。
#
#Ruby implementation of multiset and multimap.
#
#==インストール(Installation)
#
#インストールはsetup.rbによって行われます。詳しくはINSTALL.ja.txtをご覧下さい。
#
#setup.rb performs installation. See INSTALL.en.txt for more information.
#
#==更新履歴(Revision history)
#
#* Version 0.10(2008/2/9)
#  * 公開開始。
#* Version 0.11(2008/2/12)
#  * Multiset#&の実装が誤っていたのを修正。
#  * ドキュメントの間違いを修正。
#* Version 0.12(2008/2/16)
#  * Hash#to_multisetに冗長な処理があったので修正。
#  * Multisetにメソッドmap, map!, collect, collect!, map_with, map_with!を追加。
#    * これに伴い、従来のMultiset#mapなどとは挙動が変更されました。
#      （従来のMultiset#mapなどはEnumerable#mapを呼んでいたので、
#      返り値は配列でした。）
#* Version 0.13(2008/3/1)
#  * setup.rb(http://i.loveruby.net/ja/projects/setup/)を用いたインストールに対応した。
#* Version 0.131(2008/3/2)
#  * ドキュメントの間違いを修正。
#* Version 0.20(beta) (2008/3/23)
#  * Multimapクラスを追加。またこれに伴い、Hash#to_multimap・Hash#multimap
#    メソッドを追加。
#  * Multiset.parse、Multiset.parse_force、Multiset.parse_string、
#    Multiset.parse_string?メソッドを追加。
#  * Multiset#==において、引数がMultisetのインスタンスでない場合、
#    強制的にfalseを返すようにした。
#  * Multiset#subset?、Multiset#superset?、Multiset#proper_subset?、
#    Multiset#proper_superset?において、引数がMultisetのインスタンスで
#    ない場合、強制的にArgumentErrorを発生するようにした。
#* Version 0.201(beta) (2008/3/25)
#  * Multiset#classify、Multiset#classify_withの返り値をMultimapにした。
#  * Multimap#to_s、Multimap#inspectを追加。（ドキュメントは省略させていただきます）
#  * Multiset#to_sの実装が誤っていたのを修正。
#* Version 0.202(beta) (2008/4/23)
#  * GNU LGPLの文書を添付していなかったので追加。申し訳ありません。
#* Version 0.3 (2011/3/24)
#  * Rubygemsでの公開を開始。
#* Version 0.4 (2012/8/25)
#  * Rubygemsへの公開版にテストケースを追加。
#  * Multiset.parse_string、Multiset.parse_string?メソッドを削除。
#    * Ruby1.9でString#eachが削除されたため。
#      文字列を行単位で区切ってMultisetにしたい場合は、Multiset.parse_forceを
#      ご利用下さい。
#  * Multiset.from_linesメソッドを新設。（文字列のみ渡せます。挙動はMultiset.parse_forceと同じです）
#<em></em>
#* Version 0.10(2008/2/9)
#  * First distribution.
#* Version 0.11(2008/2/12)
#  * [Fixed] Wrong implementation of Multiset#&
#  * [Fixed] Wrong documentation
#* Version 0.12(2008/2/16)
#  * [Fixed] Removing redundant process in Hash#to_multiset
#  * [Added] Methods: map, map!, collect, collect!, map_with, map_with! on Multiset
#    * As a result, what Multiset#map and other methods do has changed.
#      (As of version 0.11, Multiset#map returns an array, because
#      Multiset#map means Enumerable#map.)
#* Version 0.13(2008/3/1)
#  * Made setup.rb(http://i.loveruby.net/en/projects/setup/) be avaliable.
#* Version 0.131(2008/3/2)
#  * [Fixed] Wrong documentation
#* Version 0.20(beta) (2008/3/23)
#  * [Added] Multimap class, Hash#to_multimap, Hash#multimap
#  * [Added] Multiset.parse, Multiset.parse_force, Multiset.parse_string, Multiset.parse_string?
#  * [Changed] In Multiset#==, if the argument is not an instance of Multiset,
#    Multiset#== always returns false.
#  * [Changed] In Multiset#subset?, Multiset#superset?, Multiset#proper_subset?
#    and Multiset#proper_superset?, if the argument is not an instance of Multiset,
#    those methods always raise ArgumentError.
#* Version 0.201(beta) (2008/3/25)
#  * [Changed] Multiset#classify, Multiset#classify_with returns a Multimap.
#  * [Added] Multimap#to_s, Multimap#inspect (No document)
#  * [Fixed] Wrong implementation of Multiset#to_s
#* Version 0.202(beta) (2008/4/23)
#  * Added the text of GNU LGPL to the archive. I'm very sorry...
#* Version 0.3 (2011/3/24)
#  * Released for Rubygems
#* Version 0.4 (2012/8/25)
#  * [Added] Test codes
#  * [Removed] Multiset.parse_string, Multiset.parse_string?
#    * Because Ruby 1.9 does not support String#each
#    * Multiset.parse_force is still available.
#  * [Added] Multiset.from_lines (equivalent to Multiset.parse_force, but only a string is accepted)
#
#==著作権表示(Copyright)
#
#Author::    H.Hiro(Maraigue) (http://hhiro.net/)
#Version::   0.202(beta) (2008/4/23)
#Copyright:: (C)2008 H.Hiro(Maraigue)
#
#このプログラムはMITライセンスにて提供する 無 保 証 のプログラムです。
#This program is distributed with ABSOLUTELY NO WARRANTY, under MIT License.

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
