require 'rubygems'
require 'cinch'

module Plugins
    class Say
        include Cinch::Plugin
       def initialize(*args)
          super
       end 

        match /dimelo\s*(.*)/, method: :say, :use_prefix => false
    def say(m, text)
        `say #{text}` unless text.nil? or text == ""
    end
    end
end

