require 'cinch'
require 'yaml'

require File.dirname(__FILE__) + '/../elfari_util'


module Plugins

class Player
  include Cinch::Plugin
  def self.config
      YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/../config.yml')
  end
  attr_reader :pid

  def initialize(*args)
    super
    @youtube = YouTubeIt::Client.new if @youtube.nil?

    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=7nQ2oiVqKHw')
    mplayer_bin = Player.config['mplayer']
    if @mplayer.nil?
      @mplayer = MPlayer::Slave.new flv, :path => mplayer_bin, :singleton => true, :vo => 'null'
    else
      @mplayer.load_file(flv)
    end
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
    @mplayer.load_file flv , :append

    @pid = @mplayer.pid
  end

  listen_to :join

  match /trame\s*(.*)/, method: :trame
  match /quita esta mierda/, method: :next_song
  match /que\stiene/, method: :list

  match /shh/, method: :pause
  match /apunta\s*(.*)/, method: :add_song_db
  match /ponme\s*er\s*(.*)/, method: :play_known
  match /volumen\s*(\d*)/, method: :volume

  match /vino(.*)/, method: :wine

  def pause(m)
    @mplayer.pause
    m.reply "pausa"
  end

  def volume(query)
    @mplayer.volume(:set, query.to_i * 10)
  end

  def next_song()
    @mplayer.next(1, :force)
  end

  def add_song_db(m, query)
    title = YoutubeDL::Downloader.video_title(query)
      if title.nil?
          m.reply "No me suena"
      else
         File.open('database', 'a') { |n| n.puts "#{query} - #{title}\n"}
         m.reply "#{title} en la base de datos"
      end
  end

  def wine(m)
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=-nQgsEbU9C4')
    @mplayer.load_file(flv)
    m.reply "Viva el vino!!!"
  end

  
  def play_known(m, query)
    db = File.readlines('database')
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
    db = File.readlines('database')
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
  
  match /aluego\s*(.*)/, method: :excute_aluego
  def execute_aluego(m, query)
    m.reply "HOLA"
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

  def execute(m, query)
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
    @mplayer.load_file flv , :append
  end

end
end
