require 'rubygems'
require 'cinch'

module Plugins
  class Say
    include Cinch::Plugin

    def initialize(*args)
      super
      if RUBY_PLATFORM =~ /linux/
        @cmd_es = "mpg123 -q 'http://translate.google.com/translate_tts?ie=UTF-8&tl=es&q='"
        @cmd_en = "mpg123 -q 'http://translate.google.com/translate_tts?ie=UTF-8&tl=en&q='"
      elsif RUBY_PLATFORM =~ /^win/
        raise Cinch::Exceptions::UnsupportedFeature.new "This plugin is only compatible with linux or mac"
      else
        @cmd_en = "say -v Vicki '"
        @cmd_es = "say -v Monica '"
      end
    end 
    match "jenny cuenta un chiste", method: :joke, :use_prefix => false
    match /dimelo\s*(.*)/, method: :say, :use_prefix => false
    match /say\s*(.*)/, method: :english, :use_prefix => false

    def say(m, text)
      cmd = "#{@cmd_es}#{text}'"
      %x[ #{cmd} ] 
    end

    def english(m, text)
      cmd = "#{@cmd_en}#{text}'"
      %x[ #{cmd} ]
    end

    def joke(m)
      joke = ''
      i = 4
      while joke.empty? and i > 0
        response = Nokogiri::HTML(RestClient.get URI.encode("http://www.chistescortos.eu/random"))
        response.css('a[class=oldlink]').each do |j|
          joke = j.text if j.text.length < 240
        end
        i = i - 1
      end
      return if joke.empty? and i == 0
      cmd = "#{@cmd_es}#{joke}'"
      %x[ #{cmd} ] 
    end
  end
end

