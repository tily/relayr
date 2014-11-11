Bundler.require
require './models/story.rb'
require './models/character.rb'
require './models/paragraphe.rb'
Mongoid.load!("./mongoid.yml")

desc 'new_paragraph_schema'
task :new_paragraph_schema do
	Story.all.each do |story|
		p story
	p story.paragraphs
		story.paragraphs.each do |paragraph|
			story.paragraphes.create!(body: paragraph)
		end
	end
end
