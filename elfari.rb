
# Needs rubygems and cinch:
#
# sudo apt-get install rubygems
# gem install cinch
# gem install rest-client
#

$: << File.dirname(__FILE__) + '/lib'
require 'rubygems'
require 'cinch'
require 'yaml'
require 'rest-client'
require 'alchemist'
require 'uri'
require 'em-synchrony'
require 'plugins/say'
require 'plugins/vlc'
require 'plugins/twitter'
require 'tweetstream'
##$SAFE = 4
require 'util/elfari_util'


module ElFari

  class Config
    def self.config
      YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/config/config.yml')
    end
  end

end

if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

config = ElFari::Config.config

bot = Cinch::Bot.new do
  configure do |c|
    c.server = config[:server]
    c.channels = config[:channels]
    c.nick = config[:nick]
    c.plugins.plugins = [
      Plugins::VLC, 
      Plugins::Tuiter] 

    c.plugins.options= { 
      #Plugins::Player => { :mplayer_bin => config[:mplayer], :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}" },
      Plugins::VLC => { :bin => config[:vlc][:bin],
                        :port => config[:vlc][:port],
                        :args => config[:vlc][:args],
                        :host => config[:vlc][:host],
                        :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}",
                        :internet_song => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:internet_song]}" },
    }
    c.timeouts.connect = config[:timeout]
    c.verbose = true
  end
end

EM.defer {
  bot.start
}


TweetStream.configure do |c|
  c.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  c.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  c.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
  c.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
  c.auth_method = :oauth
end
until @channel do
  bot.channels.each do |c| 
    if c.name == config[:twitter][:channel] 
      @channel = c
    end 
  end
  sleep 1 
end 

screen_name = config[:twitter][:screen_name]
TweetStream::Client.new.on_error do |message|
  @channel.msg "Error en twiiiiiiiiiiter #{message}"
end.on_direct_message do |message|
  @channel.msg "Mensajito para #{screen_name}: @#{message.sender_screen_name} #{message.text}"
end.track(screen_name) do |status|
  @channel.msg "Mencionan a #{screen_name}: @#{status.user.screen_name}: #{status.text}"
end

