# coding: utf-8
require './config.rb'

helpers do
	def story
		@story ||= Story.find(params[:id]) rescue nil
	end

	def count_characters
		count = Hash.new(0)
		story.paragraphes.each do |paragraph|
			story.characters.each do |character|
				count[character.name] += 1 if paragraph.body.match(/#{character.name}/)
			end
		end
		count
	end

	def count
		@count ||= count_characters
	end

	def character_attr(character)
		if character.errors.empty?
			{style: 'display: block'}
		else
			{style: 'display: none'}
		end
	end

	def edit_character_attr(character)
		if character.errors.empty?
			{style: 'display: none'}
		else
			{style: 'display: block'}
		end
	end

	def text_to_image_urls(text)
		YahooKeyphraseApi::Config.app_id = ENV['YAHOO_APP_ID']
		ykp = YahooKeyphraseApi::KeyPhrase.new
		result = ykp.extract(text)
		p word = result.keys.sample
		bing_image = Bing.new(ENV['BING_ACCOUNT_KEY'], 10, 'Image')
		urls = []
		bing_image.search(word).first[:Image].each do |image|
			urls << image[:MediaUrl]
		end
		urls
	end
end

get '/' do
	@stories = Story.ne(debug: true).desc(:updated_at)
	@finished = @stories.select {|story| story.finished }
	@unfinished = @stories.select {|story| !story.finished }
	haml :top
end

get '/size.txt' do
	size = 0
	@stories = Story.desc(:updated_at)
	@stories = @stories.select {|story| story.finished } if params[:finished] == 'true'
	@stories.each do |story|
		story.paragraphes.each do |paragraph|
			size += paragraph.body.size
		end
	end
	size.to_s
end

get '/rss' do
	content_type 'application/rss+xml; charset=utf8'
	@stories = Story.ne(debug: true).desc(:updated_at)
	builder :'/rss', layout: false
end

post '/' do
	@story = Story.create!(title: params[:title], size: params[:size], debug: params[:debug] == 'on')
	if params['rules']
		params['rules'].keys.sort.each do |i|
			@story.rules.create!(params['rules'][i])
		end
	end
	@paragraph = @story.paragraphes.build(body: params[:paragraph])
	if @paragraph.save
		redirect "http://#{env['HTTP_HOST']}/#{@story.id}"
	else
		@story.destroy
		p 'des'
		p @story
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
		paragraph = story.paragraphes.sample
		break if paragraph.nil? || @paragraphs.include?(paragraph)
		@paragraphs << paragraph
		@characters += story.characters.to_a
	end
	@characters.uniq!
	@paragraphs.each do |paragraph|
		@characters.each do |character|
			@count[character.name] += 1 if paragraph.body.match(/#{character.name}/)
		end
	end
	@paragraphs << Paragraphe.new(body: 'そして全員死んだ。そういうものだ。')
	haml :work
end

get '/:id' do
	story = Story.find(params[:id])
	@paragraphs = story.paragraphes
	@characters = story.characters
	halt 404 if story.nil?
	haml story.finished? ? :work : :relay
end

get '/:id/image-urls.json' do
	halt 404 if story.nil?
	halt 403 if story.finished
	content_type 'text/json'
	JSON.pretty_generate text_to_image_urls(story.paragraphes.last.body)
end

put '/:id' do
	halt 404 if story.nil?
	halt 403 if story.finished
	@story = Story.find(params[:id])
	@paragraph = @story.paragraphes.build(body: params[:paragraph])
	@story.finished = true if story.paragraphes.size == story.size
	@story.updated_at = Time.now
	if @story.finished && @story.debug
		@story.destroy
		redirect "/"

	else
		if @story.save && @paragraph.save
			redirect "http://#{env['HTTP_HOST']}/#{story.id}"
		else
			haml :relay
		end
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

put '/:id/characters/:character_id' do
	halt 404 if story.nil?
	halt 403 if story.finished
	character = story.characters.find(params[:character_id])
	if character.update(params.slice('name', 'description'))
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
