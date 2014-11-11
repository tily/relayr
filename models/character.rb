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
