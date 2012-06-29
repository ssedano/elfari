require 'cinch'
require 'rufus/scheduler'

module Plugins
    class Melee
        include Cinch::Plugin
        def initialize(*args)

           super            
           @channel = config[:channel]
           puts @channel
           raise "channel name is mandatory" if @channel.nil?
           scheduler = Rufus::Scheduler.start_new
           scheduler.cron '0 12 17 * *' do
              melee
           end
        end
      
        def melee
           Channel(@channel.split.first).send "Son las #{Time.new.hour}, melee time!"
        end
    end
end
