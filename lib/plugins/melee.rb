require 'cinch'
require 'rufus/scheduler'
require 'rubygems'
module Plugins
    class Melee
        include Cinch::Plugin
           def initialize(*args)

             super            
             @channel = config[:channel]
             puts @channel
             raise "channel name is mandatory" if @channel.nil?
    
             scheduler = Rufus::Scheduler.start_new
             scheduler.every '4s' do
               puts "mele"
             end
          end

    end





end
