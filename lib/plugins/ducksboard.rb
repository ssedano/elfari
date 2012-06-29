require 'cinch'


module Plugins
    class Ducksboard
        include Cinch::Plugin
        def initialize(*args)

            @token = config[:ducksboard_token]

            @board = "https://push.ducksboard.com/v/#{config[:board]}"
            @playlist = "https://push.ducksboard.com/v/#{config[:playlist]}"

        end


        match /Toma chato/, :method :add_song, :use_prefix => false
        match /^aluego/, :method :up, :use_prefix => false
        match /^trame/, :method :up, :use_prefix => false
        match /quita esta mierda/, :method :down, :use_prefix => false

        def add_song(m)
        end
        def up(m)
        end

        def down(m)
        end
    end
end
