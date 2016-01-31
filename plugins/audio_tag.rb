module Jekyll
	class AudioTag < Liquid::Tag
		@audio = nil

		def initialize(tag_name, markup, tokens)
			@files = markup
			super
		end

		def render(context)
			output = super
			audio = "<audio controls>"
			@files.each_line(' ') do |file|
				audio += "<source src='#{file[0...-1]}'>"
			end
			audio += "</audio>"
		end
	end
end

Liquid::Template.register_tag('audio', Jekyll::AudioTag)