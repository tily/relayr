# coding: utf-8
Bundler.require

class Story
	include Mongoid::Document
	include Mongoid::Timestamps
	field :title, type: String
	field :size, type: Integer
	field :paragraphs, type: Array
	field :finished, type: Boolean, default: false
	validates :title, length: {maximum: 35, message: 'は 35 文字以内で入力してください'}, uniqueness: true
	validates :size, inclusion: {in: 10..1000, message: 'は 10-1000 で入力してください'}
	validate do |story|
		story.errors.add(:paragraphs, "の内容が前の段落と同じです") if story.paragraphs.last == story.paragraphs[-2]
		story.errors.add(:paragraphs, "が入力されていません") if story.paragraphs.last.nil? || story.paragraphs.last == ''
		story.errors.add(:paragraphs, "は 1000 文字以内で入力してください") if story.paragraphs.last.size > 1000
	end
	has_many :characters
end

class Character
	include Mongoid::Document
	include Mongoid::Timestamps
	field :name, type: String
	field :description, type: String
	validates :name,
		length: {maximum: 14, message: "は 14 文字以内で入力してください"},
		uniqueness: {scope: :story_id, message: "は既に存在します"},
		presence: {message: "が入力されていません"}
	validates :description, length: {maximum: 140, message: "は 140 文字以内で入力してください"}
	belongs_to :story
end

configure do
        set :haml, ugly: true, escape_html: true
        Mongoid.load!("./mongoid.yml")
        TITLE = 'RELAYR'.split(//).join(' ')
end

helpers do
	def story
		@story ||= Story.find(params[:id]) rescue nil
	end

	def count_characters
		count = Hash.new(0)
		story.paragraphs.each do |paragraph|
			story.characters.each do |character|
				count[character.name] += 1 if paragraph.match(/#{character.name}/)
			end
		end
		count
	end

	def count
		@count ||= count_characters
	end
end

get '/' do
	@stories = Story.desc(:updated_at)
	@finished = @stories.select {|story| story.finished }
	@unfinished = @stories.select {|story| !story.finished }
	haml :'/'
end

post '/' do
	@story = Story.create(title: params[:title], size: params[:size], paragraphs: [params[:paragraph]])
	if @story.save
		redirect "http://#{env['HTTP_HOST']}/#{@story.id}"
	else
		haml :'/new'
	end
end

get '/new' do
	haml :'/new'
end

get '/:id' do
	halt 404 if story.nil?
	haml story.finished? ? :'/:id' : :'/:id/relay'
end

put '/:id' do
	halt 404 if story.nil?
	halt 403 if story.finished
	@story = Story.find(params[:id])
	@story.paragraphs << params[:paragraph]
	@story.finished = true if story.paragraphs.size == story.size
	if @story.save
		redirect "http://#{env['HTTP_HOST']}/#{story.id}"
	else
		haml :'/:id/relay'
	end
end

post '/:id/characters' do
	halt 404 if story.nil?
	halt 403 if story.finished
	@character = story.characters.create params.slice('name', 'description')
	if @character.save
		redirect "http://#{env['HTTP_HOST']}/#{story.id}"
	else
		haml :'/:id/relay'
	end
end

delete '/:id/characters/:character_id' do
	halt 404 if story.nil?
	halt 403 if story.finished
	@character = story.characters.find(params[:character_id])
	@character.destroy
	redirect "http://#{env['HTTP_HOST']}/#{story.id}"
end

error(403) { 'Forbidden' }
error(404) { 'Not Found' }

__END__
@@ layout
!!! 5
%html
	%head
		%meta{charset: 'utf-8'}/
		%meta{name:"viewport",content:"width=device-width,initial-scale=1.0"}
		%title= TITLE
		%script{src:"http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js",type:"text/javascript"}
		%link{rel:'stylesheet',href:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css'}
		:css
			a, a:hover { color: red; text-decoration: none; }
	%body
		%div.container
			%h1
				%a{href:'/'}= TITLE
				%small
					- if request.path == '/'
						%button.btn.btn-default.pull-right{onclick:'window.location.href="/new"'} 小説を書く
					- elsif @story
						&nbsp;
						= @story.title
					- else
						新しい小説
			%hr
			!= yield
			%hr
			%p.pull-right 2014 &copy; R E L A Y R 製作委員会
@@ /
%div.row
	%div.col-sm-6
		%h2 完結していない小説
		%ul
			- @unfinished.each do |story|
				%li
					%a{href:"/#{story.id}"}= story.title
	%div.col-sm-6
		%h2 完結した小説
		%ul
			- @finished.each do |story|
				%li
					%a{href:"/#{story.id}"}= story.title
	
@@ /new
- if @story && !@story.errors.empty?
	%ul
		- @story.errors.each do |field, error|
			%li= "#{field} #{error}"
%form.form-horizontal{method:'POST',action:"/"}
	%div.form-group
		%label.col-sm-2.control-label{for:'title'} タイトル
		%div.col-sm-10
			%input.form-control{type:'text',name:'title',value:@story.try(:title)}
	%div.form-group
		%label.col-sm-2.control-label{for:'title'} 段落数
		%div.col-sm-10
			%input.form-control{type:'number',name:'size',value:@story.try(:size)}
	%div.form-group
		%label.col-sm-2.control-label{for:'paragraph'} 書き出し
		%div.col-sm-10
			%textarea.form-control{name:'paragraph',rows:10}= @story.try(:paragraphs).try(:last)
	%div.form-group
		%div.col-sm-offset-2.col-sm-10
			%button.btn.btn-default リレー

@@ /:id
- if !@story.characters.empty?
	%h2 登場人物
	%ul.list-group
		- @story.characters.each do |character|
			%li.list-group-item
				%strong= character.name
				= "..."
				= character.description
				%span.badge= count[character.name]
%h2 本文
- story.paragraphs.each do |paragraph|
	%p= paragraph

@@ /:id/relay
%ul
	%li
		この小説は
		= story.created_at.strftime('%Y 年 %m 月 %d 日 %H 時 %M 分')
		に作成されました
	%li
		この小説は
		= story.updated_at.strftime('%Y 年 %m 月 %d 日 %H 時 %M 分')
		にリレーされました
	%li
		この小説は
		= story.size
		段落から構成され、あと
		= story.size - story.paragraphs.size
		段落で完結します
%div.row
	%div.col-md-6
		%h2 前の段落
		%p= @story.errors.empty? ? @story.paragraphs.last : @story.paragraphs[-2]
	%div.col-md-6
		%h2 次の段落
		- if !@story.errors.empty?
			%ul
				- @story.errors.each do |field, error|
					%li= "#{field} #{error}"
		%form{method:'POST',action:"/#{@story.id}"}
			%input{type:'hidden',name:'_method',value:'PUT'}
			%div.form-group
				%textarea.form-control{name:'paragraph',rows:10}
					- if !@story.errors.empty?
						= params[:paragraph]
			%div.form-group
				%button.btn.btn-default リレー
%div.row
	%div.col-md-12
		%h2 登場人物
		- if @character && !@character.errors.empty?
			%ul
				- @character.errors.each do |field, error|
					%li= "#{field} #{error}"
		%form.form-inline{method:'POST',action:"/#{@story.id}/characters",style:'padding-bottom: 1em'}
			%div.form-group
				%label 名前
				%input.form-control{name:'name'}
			%div.form-group
				%label 説明
				%input.form-control{name:'description'}
			%div.form-group
				%button.btn.btn-default.pull-right 追加
		%ul.list-group
			- @story.characters.each do |character|
				- if character != @character
					%li.list-group-item
						%strong= character.name
						= "..."
						= character.description
						%span.badge= count[character.name]
