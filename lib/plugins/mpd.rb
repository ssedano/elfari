require 'cinch'
require 'yaml'

require 'ruby-mpd'
require 'ruby-youtube-dl'
require 'em-synchrony'
require 'youtube_it'

require File.dirname(__FILE__) + '/../util/elfari_util'


module Plugins

  class MPD
    include Cinch::Plugin

    match /shh/, method: :pause, :use_prefix => false
    match /volumen\s*(\d*)/, method: :volume, :use_prefix => false
    match /quita esta mierda/, method: :next_song, :use_prefix => false
    match /apunta\s*(.+)/, method: :add_song_db, :use_prefix => false
    match /vino/, method: :wine, :use_prefix => false
    match /que\stiene/, method: :list, :use_prefix => false
    match /ponme\s*er\s*(.*)/, method: :play_known, :use_prefix => false
    match /aluego(.*)/, method: :execute_aluego, :use_prefix => false
    match /trame\s*(.*)/, method: :trame, :use_prefix => false
    match /ponmelo.*/, method: :deprecated, :use_prefix => false
    match /melee time/, method: :melee, :use_prefix => false
    match /a cuanto/, method: :get_volume, :use_prefix => false
    match /volumen\+\+/, method: :increase_volume, :use_prefix => false
    match /volume--/, method: :decrease_volume, :use_prefix => false
    match /^ponme argo\s*(.*)/, method: :play_known_random, :use_prefix => false
    match /^vamos connecta$/, method: :connect, :use_prefix => false

    def initialize(*args)
      super
      @youtube = YouTubeIt::Client.new if @youtube.nil?

      flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=7nQ2oiVqKHw')
      @db_song = config[:database]
      port = config[:mpd_port] || 6600
      uri = config[:mpd_url] || 'localhost'
      @mpd = MPD.new uri, port
      while not @mpd.connected?
        sleep 1
        @mpd.connect
      end
      @mpd.clear
      flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
      @mpd.add flv
      @mpd.play unless @mpd.playing?
    end

    listen_to :join
    def listen(m)
      flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
      @mpd.add flv
    end

    def pause(m)
      @mpd.pause
      m.reply "pausa"
    end

    def volume(m, query)
      @mpd.volume= query.to_i
    end
    def increase_volume(m)
      volume = @mpd.volume
      if volume.nil? or volume == ""
        volume = 1
      end
      volume = (volume.to_i) + 10
      volume(m, volume)
    end
    def decrease_volume(m)
      volume = @mpd.volume
      if volume.nil? or volume == ""
        volume = 1
      end
      volume = (volume.to_i) - 1
      @mpd.volume(m, volume)
    end
    def next_song(m)
      @mpd.next
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
      @mpd.clear 
      @mpd.add flv
      @mpd.play unless @mpd.playing?
      m.reply "Viva el vino!!!"
    end

    def play_known(m, query)
      @mpd.clear unless @mpd.playing?
      db = File.readlines(@db_song)
      found = false
      db.each do |line|
        if line =~ /#{query}/i
          play = line.split(/ /)[0]
          flv = YoutubeDL::Downloader.url_flv(play)
          @mpd.add(flv)
          @mpd.play unless @mpd.playing?
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

      m.reply "Tengo esto piltrafa:\n"
      db.each do |line|
        m.reply line
      end
    end

    def trame(m, query)
      @mpd.stop
      @mpd.clear
      execute_aluego(m, query)
    end

    def execute_aluego(m, query)
      @mpd.clear unless @mpd.playing?
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
        @mpd.add flv
        @mpd.play unless @mpd.playing?
        length = Time.at(video.duration).utc.strftime("%T") unless video.nil?
        m.reply "encolado " + YoutubeDL::Downloader.video_title(uri) + " directo de #{uri} (#{length})"
      end
    end

    def melee(m)
      play_known(m, 'franzl yodlling')
    end

    def get_volume(m)
      volume = @mpd.volume
      if volume.nil? or volume == ""
        m.reply "Ahora no esta sonando nada!"
      else 
        m.reply "el volume: #{volume.to_i}"
      end
    end
    def play_known_random(m)
      db = File.readlines(@db_song)
      return unless db
      song = db.at(Random.rand(db.length)) 
      play = song.split(/ /)[0]
      flv = YoutubeDL::Downloader.url_flv(play)
      if @mpd.playing?
        @mpd.add flv
      else
        @mpd.clear
        @mpd.add flv
      end
      title =YoutubeDL::Downloader.video_title(play) 
      m.reply "Tomalo, chato: #{title}"
      @mpd.play
    end

    def connect(m)
      @mpd.connect unless @mpd.connected?
    end


    def deprecated(m)
      m.reply "esta pasado de moda, mejor encola la cancion con aluego"
    end
  end
end
