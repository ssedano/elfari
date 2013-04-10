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
  end
end

