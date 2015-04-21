# coding: utf-8

namespace '/api' do
	namespace '/v1' do
		get '/stories.json' do
			# debug のものも表示するフラグ？
			@stories = Story.ne(debug: true).desc(:updated_at)
			@finished = @stories.select {|story| story.finished }
			@unfinished = @stories.select {|story| !story.finished }
			{stories: @stories}.to_json
		end

		post '/stories.json' do
			@story = Story.create!(title: params[:title], size: params[:size], debug: params[:debug] == 'on')
			if params['rules']
				params['rules'].keys.sort.each do |i|
					@story.rules.create!(params['rules'][i])
				end
			end
			@paragraph = @story.paragraphes.build(body: params[:paragraph])
			if @paragraph.save
        	                {story: {id: @story.id}}.to_json
			else
				@story.destroy
				{story: {paragraphs:[{paragraph: {errors: @paragraph.errors}}]}}.to_json
			end
		end

		get '/stories/travel.json' do
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
			{story: {paragraphs: @paragraphs, characters: @characters}}.to_json
		end

		get '/stories/:id.json' do
			story = Story.find(params[:id])
			@paragraphs = story.paragraphes
			@characters = story.characters
			halt 404 if story.nil?
			haml story.finished? ? :work : :relay
			{story: {paragraphs: @paragraphs, characters: @characters}}.to_json
		end

		post '/stories/:id/paragraphs.json' do
			halt 404 if story.nil?
			halt 403 if story.finished
			@story = Story.find(params[:id])
			@paragraph = @story.paragraphes.build(body: params[:body])
			@story.finished = true if story.paragraphes.size == story.size
			@story.updated_at = Time.now
			if @story.finished && @story.debug
				@story.destroy
				{}.to_json
			else
				if @story.save && @paragraph.save
					{}.to_json
				else
					{paragraph: {errors: @paragraph.errors}}.to_json
				end
			end
		end

		get '/stories/:id/image_urls.json' do
			halt 404 if story.nil?
			halt 403 if story.finished
			content_type 'text/json'
			{image_urls: text_to_image_urls(story.paragraphes.last.body).to_json}
		end

		delete '/stories/:id/characters/:character_id.json' do
			halt 404 if story.nil?
			halt 403 if story.finished
			@character = story.characters.find(params[:character_id])
			@character.destroy
			{}.to_json
		end

		post '/stories/:id/characters.json' do
			halt 404 if story.nil?
			halt 403 if story.finished
			@character = story.characters.create params.slice('name', 'description')
			if @character.save
				{}.to_json
			else
				{character: {errors: @character.errors}}.to_json
			end
		end

		put '/stories/:id/characters/:character_id.json' do
			halt 404 if story.nil?
			halt 403 if story.finished
			character = story.characters.find(params[:character_id])
			if character.update(params.slice('name', 'description'))
				{}.to_json
			else
				{character: {errors: character.errors}}.to_json
			end
		end
	end
end
