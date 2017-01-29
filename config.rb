# coding: utf-8
Bundler.require
require './models/story.rb'
require './models/character.rb'
require './models/paragraphe.rb'
require './models/rule.rb'

configure do
        set :haml, ugly: true, escape_html: true
        Mongoid.load!("./mongoid.yml")
        TITLE = 'RELAYR'.split(//).join(' ')
	DESCRIPTION = [
          "常に 1 つ前の段落しか読めないリレー小説投稿サイト",
          "ただし登場人物の一覧だけはいつでも登録・参照可能です",
          "小説を書きはじめるときに指定した段落数に達するまで全文は読めません"
	]
end
