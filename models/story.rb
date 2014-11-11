class Story
	include Mongoid::Document
	include Mongoid::Timestamps
	field :title, type: String
	field :size, type: Integer
	field :paragraphs, type: Array
	field :finished, type: Boolean, default: false
	validates :title, length: {maximum: 35, message: 'は 35 文字以内で入力してください'}, uniqueness: true
	validates :size, inclusion: {in: 10..1000, message: 'は 10-1000 で入力してください'}
	#validate do |story|
	#	story.errors.add(:paragraphs, "の内容が前の段落と同じです") if story.paragraphs.last == story.paragraphs[-2]
	#	story.errors.add(:paragraphs, "が入力されていません") if story.paragraphs.last.nil? || story.paragraphs.last == ''
	#	story.errors.add(:paragraphs, "は 1000 文字以内で入力してください") if story.paragraphs.last.size > 1000
	#end
	has_many :characters
	has_many :paragraphes
end
