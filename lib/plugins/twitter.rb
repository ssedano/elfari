require 'cinch'
require 'twitter'
require 'goospell'
require 'typhoeus/adapters/faraday'
require 'rest_client'
require 'nokogiri'
require 'uri'

module Plugins
  class Tuiter
    include Cinch::Plugin


    match /genardo dice\s*(.*)/, method: :tweet_genardo, :use_prefix => false
    match /nardotweet\s*(.*)/, method: :tweet_genardo, :use_prefix => false
    match /genardo sigue a\s*@(.*)/, method: :follow_genardo, :use_prefix => false
    match /rimamelo dice\s*(.*)/, method: :tweet_rimamelo, :use_prefix => false
    match /rimamelo sigue a\s*@(.*)/, method: :follow_rimamelo, :use_prefix => false
    match /genardo alecciona(.*)/, method: :lecture, :use_prefix => false
    match /genardo trendings(.*)/, method: :trends, :use_prefix => false
    match /genardo chiste(.*)/, method: :joke, :use_prefix => false

    
    def initialize(*args)
      super
      @lang = config[:lang] || 'es' 
    end

    def tweet_genardo(m, query)
      Thread.new {
        begin
          genardo = Twitter::Client.new({
            :consumer_key => ENV['GENARDO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['GENARDO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['GENARDO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['GENARDO_TWITTER_OAUTH_TOKEN_SECRET']})
          genardo.update(query.strip)
          m.reply "dicho!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end

    def follow_genardo(m, nick)
      Thread.new {
        begin
          genardo = Twitter::Client.new({
            :consumer_key => ENV['GENARDO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['GENARDO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['GENARDO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['GENARDO_TWITTER_OAUTH_TOKEN_SECRET']})
          genardo.follow(nick.strip)
          m.reply "siguiendo!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end

    def tweet_rimamelo(m, query)
      Thread.new {
        begin
          rimamelo = Twitter::Client.new({
            :consumer_key => ENV['RIMAMELO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['RIMAMELO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['RIMAMELO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['RIMAMELO_TWITTER_OAUTH_TOKEN_SECRET']})
          rimamelo.update(query.strip)
          m.reply "dicho!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end

    def follow_rimamelo(m, nick)
      Thread.new {
        begin
          rimamelo = Twitter::Client.new({
            :consumer_key => ENV['RIMAMELO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['RIMAMELO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['RIMAMELO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['RIMAMELO_TWITTER_OAUTH_TOKEN_SECRET']})
          rimamelo.follow(nick.strip)
          m.reply "siguiendo!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end

    def lecture(m, query = 'e')
      Thread.new {
        begin
          middleware = Proc.new do |builder|
            builder.use Twitter::Request::MultipartWithFile
            builder.use Faraday::Request::Multipart
            builder.use Faraday::Request::UrlEncoded
            builder.use Twitter::Response::RaiseError, Twitter::Error::ClientError
            builder.use Twitter::Response::ParseJson
            builder.use Twitter::Response::RaiseError, Twitter::Error::ServerError
            builder.adapter :typhoeus
          end
          genardo = Twitter::Client.new({
            :consumer_key => ENV['GENARDO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['GENARDO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['GENARDO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['GENARDO_TWITTER_OAUTH_TOKEN_SECRET'],
            :middleware => Faraday::Builder.new(&middleware)})

          fix = {}

          retries = 4
          while fix.empty? and retries > 0
            retries = retries - 1
            tweets = genardo.search("#{query.strip} -rt", {:count => 1, :lang => 'es', :result_type => "recent"}).results
            if tweets.empty?
              m.reply "#{query.strip} no lo veo"
              return
            end
            t = tweets[0]
            next if t.text.length > 100 or t.text.include? '@'
            text = t.text

            tt = text.split.reject { |n| n.start_with? '#' or n.start_with? '@' }
            fix = Goospell::spell(tt.join(' '), 'es')
          end

          if fix.empty?
            return
          end
          m.reply "@#{t.user.screen_name} menudo cateto: #{text}"
          fix.each do |w, f|
            text.sub!(w, f[0]) unless f.empty?
          end
          re = "Se escribe: #{text}. #deNada @#{t.user.screen_name}, no @rimamelo?"
          m.reply "Voy a tweetear #{re}"
          genardo.update(re)
          m.reply "dicho!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end

    def trends(m, query = 'espana')
      Thread.new {
        begin
          middleware = Proc.new do |builder|
            builder.use Twitter::Request::MultipartWithFile
            builder.use Faraday::Request::Multipart
            builder.use Faraday::Request::UrlEncoded
            builder.use Twitter::Response::RaiseError, Twitter::Error::ClientError
            builder.use Twitter::Response::ParseJson
            builder.use Twitter::Response::RaiseError, Twitter::Error::ServerError
            builder.adapter :typhoeus
          end
          genardo = Twitter::Client.new({
            :consumer_key => ENV['GENARDO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['GENARDO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['GENARDO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['GENARDO_TWITTER_OAUTH_TOKEN_SECRET'],
            :middleware => Faraday::Builder.new(&middleware)})
          query = 'espana' if query.empty?
          woeid = '23424950'

          appid = ENV['YAHOO_APPID']
          response = RestClient.get URI.encode("http://where.yahooapis.com/v1/places.q('#{query.strip}')"), {:params => {:appid => appid}}
          if response.code == 200
            xml = Nokogiri.XML response.body
            woeid = xml.at_css('place/woeid').text if xml.at_css('place/woeid')
          end
          m.reply "Toma los trendin' topics"
          genardo.local_trends(woeid).each do |trend|
            m.reply "- #{trend.name}"
          end
          m.reply "Pon uno en tu tweet!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end

    def joke(m, query)
      Thread.new {
        begin
          middleware = Proc.new do |builder|
            builder.use Twitter::Request::MultipartWithFile
            builder.use Faraday::Request::Multipart
            builder.use Faraday::Request::UrlEncoded
            builder.use Twitter::Response::RaiseError, Twitter::Error::ClientError
            builder.use Twitter::Response::ParseJson
            builder.use Twitter::Response::RaiseError, Twitter::Error::ServerError
            builder.adapter :typhoeus
          end
          genardo = Twitter::Client.new({
            :consumer_key => ENV['GENARDO_TWITTER_CONSUMER_KEY'],
            :consumer_secret => ENV['GENARDO_TWITTER_CONSUMER_SECRET'],
            :oauth_token => ENV['GENARDO_TWITTER_OAUTH_TOKEN'],
            :oauth_token_secret => ENV['GENARDO_TWITTER_OAUTH_TOKEN_SECRET'],
            :middleware => Faraday::Builder.new(&middleware)})

          joke = ''
          response = Nokogiri::HTML(RestClient.get URI.encode("http://www.chistescortos.eu/random"))
          response.css('a[class=oldlink]').each do |j|
            joke = j.text if j.text.length < 120
          end
          return if joke.empty?
          m.reply "#{joke} #chiste"
          genardo.update("#{joke} #chiste #deNada")
          m.reply "dicho!"
        rescue Twitter::Error => fail
          m.reply "No pueeeeedo: #{fail}"
        rescue Exception => fail
          m.reply "No pueeeedo: #{fail}"
        end
      }
    end
  end
end

