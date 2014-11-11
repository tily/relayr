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
	DESCRIPTION = [
          "常に 1 つ前の段落しか読めないリレー小説投稿サイト",
          "ただし登場人物の一覧だけはいつでも登録・参照可能です",
          "小説を書きはじめるときに指定した段落数に達するまで全文は読めません"
	]
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
	haml :top
end

get '/size.txt' do
	size = 0
	@stories = Story.desc(:updated_at)
	@stories = @stories.select {|story| story.finished } if params[:finished] == 'true'
	@stories.each do |story|
		story.paragraphs.each do |paragraph|
			size += paragraph.size
		end
	end
	size.to_s
end

get '/rss' do
	content_type 'application/rss+xml; charset=utf8'
	@stories = Story.desc(:updated_at)
	builder :'/rss', layout: false
end

post '/' do
	@story = Story.create(title: params[:title], size: params[:size], paragraphs: [params[:paragraph]])
	if @story.save
		redirect "http://#{env['HTTP_HOST']}/#{@story.id}"
	else
		haml :new
	end
end

get '/new' do
	haml :new
end

get '/travel' do
	size = params[:size] || 10
	@count = Hash.new(0)
	@paragraphs = []
	@characters = []
	until @paragraphs.size == size
		story = Story.all.sample
		paragraph = story.paragraphs.sample
		break if @paragraphs.include?(paragraph)
		@paragraphs << paragraph
		@characters += story.characters.to_a
	end
	@characters.uniq!
	@paragraphs.each do |paragraph|
		@characters.each do |character|
			@count[character.name] += 1 if paragraph.match(/#{character.name}/)
		end
	end
	@paragraphs << 'そして全員死んだ。そういうものだ。'
	haml :work
end

get '/:id' do
	story = Story.find(params[:id])
	@paragraphs = story.paragraphs
	@characters = story.characters
	halt 404 if story.nil?
	haml story.finished? ? :work : :relay
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
		haml :relay
	end
end

post '/:id/characters' do
	halt 404 if story.nil?
	halt 403 if story.finished
	@character = story.characters.create params.slice('name', 'description')
	if @character.save
		redirect "http://#{env['HTTP_HOST']}/#{story.id}"
	else
		haml :relay
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
