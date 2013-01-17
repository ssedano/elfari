require 'cinch'
require 'yaml'

require 'vlcrc'
require 'ruby-youtube-dl'
require 'em-synchrony'
require 'youtube_it'

require File.dirname(__FILE__) + '/../util/elfari_util'


module Plugins

  class VLC
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
    match /^volumen\+\+$/, method: :increase_volume, :use_prefix => false
    match /^volume--$/, method: :decrease_volume, :use_prefix => false
    match /^dale$/, method: :play, :use_prefix => false
    match /^ponme argo\s*(.*)/, method: :play_known_random, :use_prefix => false

    def initialize(*args)
      super
      @youtube = YouTubeIt::Client.new if @youtube.nil?

      windows = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=7nQ2oiVqKHw')
      @db_song = config[:database]

      config[:host] ||= 'localhost'
      config[:port] ||= 1234
      config[:args] ||= '--no-video -I lua --lua-intf cli --ignore-config'
      if config[:bin].nil?
        @vlc = VLCRC::VLC.new config[:host], config[:port], config[:args]
      else
        @vlc = VLCRC::VLC.new config[:host], config[:port], config[:bin], config[:args]
      end
      @vlc.launch

      # Connect to it (have to wait for it to launch though)
      until @vlc.connected?
        sleep 0.1
        @vlc.connect
      end
      flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')


      @vlc.clear_playlist

      @vlc.add_stream  windows
      @vlc.add_stream  flv
      @vlc.playing = true

    end

    listen_to :join
    def listen(m)
      flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
      if @vlc.playing
        @vlc.add_stream flv
      else
        @vlc.clear_playlist
        @vlc.stream= flv
      end
    end

    listen_to :disconnect
    def disconnect(m)
      @vlc.stream= @internet_song
      @vlc.playing= true
    end

    def pause(m)
      @vlc.pause
      m.reply "pausa"
    end

    def volume(m, query)
      @vlc.volume=query.to_i
    end
    def increase_volume(m)
      vol = @vlc.volume
      if vol.nil? or vol == ""
        vol = 1
      end
      vol = vol.to_i + 10
      volume(m, vol)
    end
    def decrease_volume(m)
      vol = @vlc.volume
      if vol.nil? or vol == ""
        vol = 1
      end
      vol = vol.to_i - 10
      @vlc.volume(m, vol)
    end
    def next_song(m)
      @vlc.next
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
      @vlc.stream=  flv
      m.reply "Viva el vino!!!"
    end

    def play_known(m, query)
      db = File.readlines(@db_song)
      found = false
      db.each do |line|
        if line =~ /#{query}/i
          play = line.split(/ /)[0]
          flv = YoutubeDL::Downloader.url_flv(play)
          if @vlc.playing
            @vlc.add_stream flv
          else
            @vlc.clear_playlist
            @vlc.stream=flv
          end
          title =YoutubeDL::Downloader.video_title(play) 
          m.reply "Tomalo, chato: #{title}"
          found = true
          break
        end
      end
      m.reply "No tengo er: #{query}" if !found

      @vlc.playing=true if found
    end

    def list(m)
      db = File.readlines(@db_song)

      m.reply "Tengo esto piltrafa:\n"
      db.each do |line|
        m.reply line
      end
    end

    def trame(m, query)
      video = @youtube.videos_by(:query => query, :max_results => 1).videos.at(0)
      if video.nil?
        m.reply "no veo el #{query}"
      else
        flv = YoutubeDL::Downloader.url_flv(video.player_url)
        @vlc.clear_playlist
        @vlc.stream= flv
        m.reply "Toma " + YoutubeDL::Downloader.video_title(video.player_url) + " directo de #{video.player_url} (#{Time.at(video.duration).utc.strftime("%T")})"
        @vlc.playing=true
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
        if @vlc.playing
          @vlc.add_stream flv
        else
          @vlc.clear_playlist
          @vlc.stream= flv
        end
        length = Time.at(video.duration).utc.strftime("%T") unless video.nil?
        m.reply "encolado " + YoutubeDL::Downloader.video_title(uri) + " directo de #{uri} (#{length})"
        @vlc.playing=true
      end
    end

    def melee(m)
      play_known(m, 'franzl')
    end

    def get_volume(m)
      vol = @vlc.volume
      if vol.nil? or vol == ""
        m.reply "Ahora no esta sonando nada!"
      else 
        m.reply "el volume: #{vol.to_i}"
      end
    end

    def deprecated(m)
      m.reply "esta pasado de moda, mejor encola la cancion con aluego"
    end
    def play_known_random(m)
      db = File.readlines(@db_song)
      return unless db
      song = db.at(Random.rand(db.length)) 
      play = song.split(/ /)[0]
      flv = YoutubeDL::Downloader.url_flv(play)
      if @vlc.playing
        @vlc.add_stream flv
      else
        @vlc.clear_playlist
        @vlc.stream=flv
      end
      title =YoutubeDL::Downloader.video_title(play) 
      m.reply "Tomalo, chato: #{title}"
      @vlc.playing=true
    end

    def play()
      @vlc.playing=true
    end
  end
end
