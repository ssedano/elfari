
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

bot = Cinch::Bot.new do
  configure do |c|
    c.server = config[:server]
    c.channels = config[:channels]
    c.nick = config[:nick]
    c.plugins.plugins = [Plugins::VLC, 
                         Plugins::Say] 
    
    c.plugins.options= { 
      #Plugins::Player => { :mplayer_bin => config[:mplayer], :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}" },
        Plugins::VLC => { :bin => config[:vlc][:bin],
                          :port => config[:vlc][:port],
                          :args => config[:vlc][:args],
                          :host => config[:vlc][:host] }}
    c.timeouts.connect = config[:timeout]
    c.verbose = true
  end
end

EM.run {bot.start}
