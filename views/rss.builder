xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0", :"xmlns:atom" => "http://www.w3.org/2005/Atom" do
	xml.channel do
		xml.tag! "atom:link", :href => "http://relayr.herokuapp.com/rss", :rel => "self", :type => "application/rss+xml"
		xml.title "R E L A Y R"
		xml.description DESCRIPTION.join(' / ')
		xml.link "http://relayr.herokuapp.com/"
		@stories.limit(20).each do |story|
			xml.item do
				xml.title "「#{story.title}」第 #{story.paragraphs.size} 話"
				if story.finished
					xml.description story.paragraphs.join("\n\n")
				else
					xml.description story.paragraphs.last
				end
				xml.link "http://relayr.herokuapp.com/#{story.id}##{story.paragraphs.size}"
				xml.pubDate story.updated_at.rfc822
				xml.guid "http://relayr.herokuapp.com/#{story.id}##{story.paragraphs.size}"
			end
		end
	end
end
