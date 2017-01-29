# coding: utf-8
require 'prime'

class Rule
	include Mongoid::Document
	include Mongoid::Timestamps

	field :type, type: String
	field :body, type: String
	field :target, type: String
	field :target_number, type: Integer

	validates :type,
		inclusion: {in: ["free", "starts with", "includes", "not include", "ends with", "regexp"]}
	validates :body,
		length: {maximum: 140, message: "は 140 文字以内で入力してください"},
		presence: {message: "が入力されていません"}
	validates :target,
		inclusion: {in: ["all", "multiples of", "number", "odd", "even", "prime"]}
	validates :target_number,
		length: {minimum: 0, maximum: 1000}

	belongs_to :story

	def to_ja
		subject = case target
			when 'all'; 'すべて'
			when 'odd'; '奇数'
			when 'even'; '偶数'
			when 'prime'; '素数'
			when 'number'; "#{target_number} 番目"
			when 'multiples of'; "#{target_number} の倍数"
		end
		predicate = case type
			when 'free'; body
			when 'starts with'; "「#{body}」で始まらなければならない"
			when 'includes'; "「#{body}」を含まなければならない"
			when 'not include'; "「#{body}」を含んではならない"
			when 'ends with'; "「#{body}」で終わらなければならない"
			when 'regexp'; "/#{body}/ にマッチしなければならない" 
		end
		"#{subject}の段落が#{predicate}"
	end

	def target_paragraph?(paragraph)
		paragraph_number = paragraph.story.paragraphes.size
		target == 'all' ||
		target == 'number' && target_number == paragraph_number ||
		target == 'multiples of' && paragraph_number % target_number == 0 ||
		target == 'even' && paragraph_number.even? ||
		target == 'odd' && paragraph_number.odd? ||
		target == 'prime' && Prime.prime?(paragraph_number)
	end

	def validate_paragraph(paragraph)
		case type
		when 'starts with'
			if !paragraph.body[/^#{self.body}/]
				paragraph.errors.add(:body, self.to_ja)
			end
		when 'includes'
			if !paragraph.body[/#{self.body}/]
				paragraph.errors.add(:body, self.to_ja)
			end
		when 'not includes'
			if paragraph.body[/#{self.body}/]
				paragraph.errors.add(:body, self.to_ja)
			end
		when 'ends with'
			if !paragraph.body[/#{self.body}$/]
				paragraph.errors.add(:body, self.to_ja)
			end
		when 'regexp'
			if !paragraph.body[Regexp.compile(body)]
				paragraph.errors.add(:body, self.to_ja)
			end
		end
	end
end
