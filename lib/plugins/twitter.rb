require 'cinch'
require 'twitter'

module Plugins
  class Tuiter
    include Cinch::Plugin

    match /genardo dice\s*(.*)/, method: :tweet, :use_prefix => false
    match /genardo sigue a\s*@(.*)/, method: :follow, :use_prefix => false

    def initialize(*args)
      super

      Twitter.configure do |c|
        c.consumer_key = ENV['TWITTER_CONSUMER_KEY']
        c.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
        c.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
        c.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
      end
    end


    def tweet(m, query)
      begin
        Twitter.update(query.strip)
        m.reply "dicho!"
      rescue Twitter::Error => fail
        m.reply "No pueeeeedo: #{fail}"
      rescue Exception => fail
        m.reply "No pueeeedo: #{fail}"
      end
    end

    def follow(m, nick)
      begin
        Twitter.follow(nick.strip)
        m.reply "siguiendo!"
      rescue Twitter::Error => fail
        m.reply "No pueeeeedo: #{fail}"
      rescue Exception => fail
        m.reply "No pueeeedo: #{fail}"
      end
    end

  end
end
