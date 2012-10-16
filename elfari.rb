
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
require 'plugins/player'
require 'plugins/melee'
require 'plugins/git'
require 'plugins/mothership'
require 'plugins/say'
require 'plugins/vlc'
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
WeBee::Api.user = config[:abiquo][:user]
WeBee::Api.password = config[:abiquo][:password]
WeBee::Api.url = "http://#{config[:abiquo][:host]}/api"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = config[:server]
    c.channels = config[:channels]
    c.nick = config[:nick]
    c.plugins.plugins = [Plugins::VLC, 
                         Plugins::Melee,
                         Plugins::GitDude,
                         Plugins::Say, 
                         Plugins::Mothership] 
    
    c.plugins.options= { 
      #Plugins::Player => { :mplayer_bin => config[:mplayer], :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}" },
        Plugins::VLC => { :bin => config[:vlc][:bin],
                          :port => config[:vlc][:port],
                          :args => config[:vlc][:args],
                          :host => config[:vlc][:host] },
        Plugins::Melee => { :channel => config[:melee][:channel] }, 
        Plugins::Mothership => { :api_user => config[:abiquo][:user],
                                 :api_password => config[:abiquo][:password],
                                 :ip => config[:abiquo][:host] }} 
    c.timeouts.connect = config[:timeout]
    c.verbose = true
  end
  
 on :message, /rimamelo (.*)/ do |m, query|
  	uri = "http://rimamelo.herokuapp.com/web/api?model.rhyme=#{URI.escape(query)}"
        rhyme = RestClient.get(uri)
        rhyme["<rhyme>"] = ""
        rhyme["</rhyme>"] = ""
        rhyme["<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"] = ""
        m.reply "#{rhyme}"
        @elfari_port = ElFari::Config.config[:elfari][:port]
        @elfari_url = ElFari::Config.config[:elfari][:port]
        RestClient.post "http://#{@elfari_url}:#{@elfari_port}/say", :text => "#{rhyme}"
  end

 
end

EM.run {bot.start}
