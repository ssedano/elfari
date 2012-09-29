require 'cinch'
require 'Ducksboard'

module Plugins
    class DucksboardPlugin
        include Cinch::Plugin
        def initialize(*args)

            super
            @API = Ducksboard
            @API.api_key = config[:ducksboard_token]
            @board = @API::Leaderboard.new(config[:board])
       
            @leaders = @board.last_values(1)["data"][0]["value"]
            @leaders = @leaders["board"] if @leaders.has_key?("board")      
            puts @leaders
            @leaders=  @leaders.to_a 
        end

        listen_to :join
        react_on :channel

        def listen(m)
            if m.user.nick == bot.nick
                m.channel.users.each { |a,b| @leaders.insert(0, {"name" => a.nick, "values" => [0, 0, 0]}) unless @leaders.each { |l| l["name"] == a.nick}} 
                puts "no #{@leaders }" 
            else
                #@leaders = { "name" => m.user.nick, "values" => [0, 0, 0]}) unless @leaders.find { |l| l.values[0] == m.user.nick }  
            end
           
           @board.linha = @leaders 
          puts @board 
            @board.save 
        end
        def add_song(m)

        end
        def up(m)
        end

        def down(m)
        end
    end
end



