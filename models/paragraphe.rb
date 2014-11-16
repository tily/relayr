class Paragraphe
	include Mongoid::Document
	include Mongoid::Timestamps
	field :body, type: String
	validates :body,
		length: {maximum: 1000, message: "は 1000 文字以内で入力してください"},
		presence: {message: "が入力されていません"},
		uniqueness: {message: "の内容が前の段落と同じです", scope: :story_id}
	belongs_to :story
	has_many :characters

	validate do |paragraph|
		paragraph.story.rules.each do |rule|
			if rule.target_paragraph?(paragraph)
				rule.validate_paragraph(paragraph)
			end
		end
	end
end
