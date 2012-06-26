require 'cinch'
require 'yaml'

require 'mplayer-ruby'
require 'ruby-youtube-dl'
require 'em-synchrony'
require 'youtube_it'

require File.dirname(__FILE__) + '/../util/elfari_util'


module Plugins

class Player
  include Cinch::Plugin

  attr_reader :pid

  match /shh/, method: :pause, :use_prefix => false
  match /volumen\s*(\d*)/, method: :volume, :use_prefix => false
  match /quita esta mierda/, method: :next_song, :use_prefix => false
  match /apunta\s*(.+)/, method: :add_song_db, :use_prefix => false
  match /vino/, method: :wine, :use_prefix => false
  match /que\stiene/, method: :list, :use_prefix => false
  match /ponme\s*er\s*(.*)/, method: :play_known, :use_prefix => false
  match /aluego(.*)/, method: :execute_aluego, :use_prefix => false
  match /trame\s*(.*)/, method: :trame, :use_prefix => false
	  
  def initialize(*args)
    super
    @youtube = YouTubeIt::Client.new if @youtube.nil?

    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=7nQ2oiVqKHw')
    @db_song = config[:database]
    puts @db_song
    if config[:mplayer_bin].nil?
      @mplayer = MPlayer::Slave.new flv, :singleton => true, :vo => 'null'
    else
      @mplayer = MPlayer::Slave.new flv, :path => config[:mplayer_bin], :singleton => true, :vo => 'null'
    end
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
    @mplayer.load_file flv , :append
    @pid = @mplayer.pid
  end
  
  listen_to :join
  def execute(m, query)
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
    @mplayer.load_file flv , :append
  end
  
  def pause(m)
    @mplayer.pause
    m.reply "pausa"
  end
  
  def volume(m, query)
    @mplayer.volume(:set, query.to_i * 10)
  end
  
  def next_song(m)
    @mplayer.next(1, :force)
  end

  def add_song_db(m, query)
      if query.match(/^http/)
        title = YoutubeDL::Downloader.video_title(query)
        if title.nil?
           m.reply "No me suena"
        else
          File.open(@db_song, 'a') { |n| n.puts "#{query} - #{title}\n"}
          m.reply "#{title} en la base de datos"
        end
      else
          m.reply "eso no es una uri"
      end
  end
  
  def wine(m)
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=-nQgsEbU9C4')
    @mplayer.load_file(flv)
    m.reply "Viva el vino!!!"
  end

  def play_known(m, query)
    db = File.readlines(@db_song)
    found = false
    db.each do |line|
      if line =~ /#{query}/i
        play = line.split(/ /)[0]
        flv = YoutubeDL::Downloader.url_flv(play)
        @mplayer.load_file(flv)
        title =YoutubeDL::Downloader.video_title(play) 
        m.reply "Tomalo, chato: #{title}"
        found = true
        break
      end
    end
  	m.reply "No tengo er: #{query}" if !found
  end
  
  def list(m)
    db = File.readlines(@db_song)
    list = "Tengo esto piltrafa:\n"
    i=1
    db.each do |line|
      f=line.split(/ - /)[0].length + 3
      list += i.to_s() + " " + line[f..line.length]
      i+=1
    end
	m.reply "#{list}"
  end
  
  def trame(m, query)
      video = @youtube.videos_by(:query => query, :max_results => 1).videos.at(0)
      if video.nil?
          m.reply "no veo el #{query}"
      else
          flv = YoutubeDL::Downloader.url_flv(video.player_url)
          @mplayer.load_file(flv)
          m.reply "Toma " + YoutubeDL::Downloader.video_title(video.player_url) + " directo de #{video.player_url} (#{Time.at(video.duration).utc.strftime("%T")})"
      end
  end
  
  def execute_aluego(m, query)
    length = "UNKNOWN LENGTH"
    if /http:\/\//.match(query)
      uri = query
    else
      video = @youtube.videos_by(:query => query, :max_results => 1).videos.at(0)
      uri = video.player_url unless video.nil?
    end
    if uri.nil?
      m.reply "no veo el #{query}"
    else
      flv = YoutubeDL::Downloader.url_flv(uri)
      @mplayer.load_file flv, :append
      length = Time.at(video.duration).utc.strftime("%T") unless video.nil?
      m.reply "encolado " + YoutubeDL::Downloader.video_title(uri) + " directo de #{uri} (#{length})"
    end
  end
end
end
