
# Needs rubygems and cinch:
#
# sudo apt-get install rubygems
# gem install cinch
# gem install rest-client
#
$: << File.dirname(__FILE__) + "/modules"
require 'rubygems'
require 'webee'
require 'cinch'
require 'yaml'
require 'rest-client'
require 'alchemist'
require 'rufus/scheduler'
require 'abiquo-deployer'
require 'uri'
require 'mplayer-ruby'
require 'ruby-youtube-dl'
require 'em-synchrony'
require 'youtube_it'
##$SAFE = 4
require File.dirname(__FILE__) + '/elfari_util'
module ElFari

  class Config

    def self.config
      YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/config.yml')
    end

  end

end

class Motherfuckers
  include Cinch::Plugin

  timer 900, method: :say
  def say
    ElFari::Config.config[:channels].each do |c|
      Channel(c.split.first).send "Any news, motherfuckers?"
    end
  end

end

class GitDude
  include Cinch::Plugin

  timer 5, method: :new_stuff
  def new_stuff
    conf = ElFari::Config.config[:gitdude]
    conf[:repos].each do |r|
      next if not File.directory?(r[:path])
      ENV['GIT_DIR'] = r[:path] + '/.git'
      changes = []
      `git fetch -v 2>&1 | grep -F -- '->'`.each_line do |l|
        if l =~ /.*\.\..*/
          changes << l
        end
      end
      changes.each do |l|
        tokens = l.split
        commit_range = tokens[0]
        branch_name = tokens[1]
        commit_messages = `git log #{commit_range} --pretty=format:'%s (%an)'`
        ElFari::Config.config[:channels].each do |c|
          commit_messages.each_line do |l|
            Channel(c.split.first).send  "* [#{r[:name]}] #{l}\n\n"
          end
        end
      end
    end
  end
end

if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

conf = ElFari::Config.config
WeBee::Api.user = conf[:abiquo][:user]
WeBee::Api.password = conf[:abiquo][:password]
WeBee::Api.url = "http://#{conf[:abiquo][:host]}/api"
@youtube = YouTubeIt::Client.new
class ControlWS
  
  def self.say(text, voice = :spanish)
    if voice == :english
      @elfari_port = ElFari::Config.config[:elfari][:port]
      @elfari_url = ElFari::Config.config[:elfari][:url]
      RestClient.post "http://#{@elfari_url}:#{@elfari_port}/say", :text => text, :voice => 'Alex'
    else
       @elfari_port = ElFari::Config.config[:elfari][:port]
       @elfari_url = ElFari::Config.config[:elfari][:url]
       RestClient.post "http://#{@elfari_url}:#{@elfari_port}/say", :text => text
    end
  end

end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = conf[:server]
    c.channels = conf[:channels]
    c.nick = conf[:nick]
    #c.plugins.plugins = [Motherfuckers]
    c.timeouts.connect = conf[:timeout]
  end
  scheduler = Rufus::Scheduler.start_new
  
  @ring = false 
  def bells
      ElFari::Config.config[:channels].each do |c|
          Channel(c.split.first).send "Son las #{Time.new.hour}"
      end
      Time.new.hour.times { %x[beep  2&>1 && sleep 1]} if @ring
  end

  scheduler.cron '0 * * * *' do
      bells
  end

  on :message, /\s*con campanadas\s*/ do |m, query|
      @ring = true
      m.reply "Las horas con beeps, para desactivarlo: s/con/sin/"
  end
  on :message, /\s*sin campandas\s*/ do |m, query|
      @ring = false
      m.reply "Sin campanadas"
  end
  @elfari_url = ElFari::Config.config[:elfari][:url]
  raise "Invalid elfari url" unless @elfari_url
  
  @mplayer_bin = ElFari::Config.config[:mplayer]
  raise "Mplayer not present" if @mplayer_bin.nil?
  #on :message, /ponmelo\s*(http:\/\/www\.youtube\.com.*)/ do |m, query|
    #RestClient.post "http://@elfari_url:@elfari_port/youtube", :url => query
    #title = RestClient.get('http://@elfari_url:@elfari_port/current_video')
    #while title.nil? or title.strip.chomp.empty?
      #title = RestClient.get('http://@elfari_url:@elfari_port/current_video')
    #end
    #m.reply "Tomalo, chato: #{title}"
  #end
  on :message, /dimelo (.*)/ do |m, query|
    @elfari_url = ElFari::Config.config[:elfari][:url]
    @elfari_port = ElFari::Config.config[:elfari][:port]
    RestClient.post "http://#{@elfari_url}:#{@elfari_port}/say", :text => query
  end
  on :message, /in-inglis (.*)/ do |m, query|
    @elfari_url = ElFari::Config.config[:elfari][:url]
    @elfari_port = Elfari::Config.config[:elfari][:port]
    RestClient.post "http://#{@elfari_url}:#{@elfari_port}/say", :text => query, :voice => 'Alex'
  end
  on :message, /ayudame/ do |m|
    m.reply 'Ahi van los comandos, chavalote!: ayudame dimelo ponmelo volumen mele in-inglis ponmeargo ponmeer quetiene'
  end
  on :message, /volumen\s*(\d*)/ do |m, query|
        @mplayer.volume(:set, query.to_i * 10) unless @mplayer.nil?
  end
  on :message, /mele/ do |m, query|
    RestClient.post "http://#{@elfari_url}:#{@elfari_port}/video", :url => 'http://gobarbra.com/hit/new-0416a9aa8de56543b149d7ffb477196f'
    m.reply "Paralo Paul!!!"
  end
  on :message, /vino/ do |m, query|
    flv = YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=-nQgsEbU9C4')
    @mplayer_bin = ElFari::Config.config[:mplayer]
    if @mplayer.nil?
        @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null'
    else
        @mplayer.load_file(flv)
    end
    m.reply "Viva el vino!!!"
  end
  on :message, /ponme\s*argo\s*(.*)/ do |m, query|
    db = File.readlines('database')
    play = db[(rand * (db.size - 1)).to_i].split(/ /)[0]
    @mplayer_bin = ElFari::Config.config[:mplayer]
    flv = YoutubeDL::Downloader.url_flv(play)
    if @mplayer.nil?
       @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null'
    else
       @mplayer.load_file(flv)
    end
    title =YoutubeDL::Downloader.video_title(play) 
    m.reply "Tomalo, chato: #{title}"
  end
   on :message, /ponmelo\s*(http:\/\/www\.youtube\.com.*)/ do |m, query|
    flv = YoutubeDL::Downloader.url_flv(query)
    @mplayer_bin = ElFari::Config.config[:mplayer]
    if @mplayer.nil?
        @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null' #("-vo null -prefer-ipv4 ")
    else
        @mplayer.load_file(flv)
    end
    m.reply "Tomalo, chato: " + YoutubeDL::Downloader.video_title(query)
  end
  on :message, /ponmelo\s*(http:\/\/www\.youtube\.com.*)\s*en\s*el\s*(.*)\s?/ do |m, query, seek|
    time = ElFariUtil.extract_seek_time(seek)
    @mplayer_bin = ElFari::Config.config[:mplayer]
    flv = YoutubeDL::Downloader.url_flv(query)
    if @mplayer.nil?
        @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null' #("-vo null -prefer-ipv4 ")
    else
        @mplayer.load_file(flv)
    end
    @mplayer.seek(time, :absolute) unless @mplayer.nil?
    m.reply "Tomalo, chato: " + YoutubeDL::Downloader.video_title(query)
  end
 
  on :message, /ponme\s*er\s*(.*)/ do |m, query|
    db = File.readlines('database')
    found = false
    db.each do |line|
      if line =~ /#{query}/i
        play = line.split(/ /)[0]
        @mplayer_bin = ElFari::Config.config[:mplayer]
        flv = YoutubeDL::Downloader.url_flv(play)
        if @mplayer.nil?
           @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null'
        else
           @mplayer.load_file(flv)
        end
        title =YoutubeDL::Downloader.video_title(play) 
        m.reply "Tomalo, chato: #{title}"
        found = true
        break
      end
    end
  	m.reply "No tengo er: #{query}" if !found
  end

  on :message, /apunta\s*(http:\/\/www\.youtube\.com.*)/ do |m, query|
      title = YoutubeDL::Downloader.video_title(query)
      if title.nil?
          m.reply "No me suena"
      else
         File.open('database', 'a') { |n| n.puts "#{query} - #{title}\n"}
         m.reply "#{title} en la base de datos"
      end
  end

  on :message, /aluego\s*(.*)/ do |m, query|
      if @youtube.nil?
          @youtube = YouTubeIt::Client.new
      end
      video = @youtube.videos_by(:query => query, :max_results => 1).videos.at(0)
      if video.nil?
          m.reply "no veo el #{query}"
      else
          flv = YoutubeDL::Downloader.url_flv(video.player_url)
          @mplayer_bin = ElFari::Config.config[:mplayer]
          if @mplayer.nil?
              @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null'
          else
              @mplayer.load_file flv, :append
          end
          m.reply "Toma " + YoutubeDL::Downloader.video_title(video.player_url) + " directo de #{video.player_url} (#{Time.at(video.duration).utc.strftime("%T")})"
      end
  end
on :message, /trame\s*(.*)/ do |m, query|
      if @youtube.nil?
          @youtube = YouTubeIt::Client.new
      end
      video = @youtube.videos_by(:query => query, :max_results => 1).videos.at(0)
      if video.nil?
          m.reply "no veo el #{query}"
      else
          flv = YoutubeDL::Downloader.url_flv(video.player_url)
          @mplayer_bin = ElFari::Config.config[:mplayer]
          if @mplayer.nil?
              @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null'
          else
              @mplayer.load_file(flv)
          end
          m.reply "Toma " + YoutubeDL::Downloader.video_title(video.player_url) + " directo de #{video.player_url} (#{Time.at(video.duration).utc.strftime("%T")})"
      end
  end
  on :message, /luego\s*(http:\/\/www\.youtube\.com.*)/ do |m, query|
      flv = YoutubeDL::Downloader.url_flv(query)
      @mplayer_bin = ElFari::Config.config[:mplayer]
      if @mplayer.nil?
          @mplayer = MPlayer::Slave.new flv, :path => @mplayer_bin, :singleton => true, :vo => 'null'
      else
          @mplayer.load_file flv, :append
      end
      m.reply "Luego te pongo " + YoutubeDL::Downloader.video_title(query)
  end
  on :message, /que\s*tiene/ do |m, query|
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

  on :message, /mothership abusers/ do  |m, query|
    abusers = {}
    WeBee::Enterprise.all.each do |ent|
      ent.users.each do |user|
        vms = (user.virtual_machines.find_all{ |vm| vm.state == 'RUNNING'})
        abusers[user.name] = { :full_name => "#{user.name} #{user.surname}", :email => user.email, :vms_number => vms.size, :vms => vms }
      end
    end

    abusers = abusers.sort do |a,b|
      a[1][:vms_number] <=> b[1][:vms_number]
    end.reverse

    m.reply "Running VMs, per user"
    abusers.each do |a|
      if a[1][:vms_number] > 0
        m.reply "User: " + "#{a[1][:full_name]}".ljust(40) + "VMs: " + "#{a[1][:vms_number]}"
      end
    end
  end

  on :message, /mothership cloud-stats/ do |m, query|
    stats = {
      :free_hd => 0, 
      :real_hd => 0,
      :used_hd => 0, 
      :hypervisors => 0,
      :free_ram => 0,
      :real_ram => 0,
      :used_ram => 0,
      :available_cpus => 0
    }
    WeBee::Datacenter.all.each do |dc|
      dc.racks.each do |rack|
        rack.machines.each do |m|
          stats[:hypervisors] += 1
          stats[:used_ram] += m.ram_used.to_i
          stats[:real_ram] += m.real_ram.to_i
          stats[:available_cpus] += m.real_cpu.to_i
          stats[:used_hd] += m.hd_used.to_i.bytes.to.gigabytes.to_f.round
          stats[:real_hd] += m.real_hd.to_i.bytes.to.gigabytes.to_f.round
        end
      end
    end
    stats[:free_ram] = stats[:real_ram] - stats[:used_ram]
    stats[:free_hd] = stats[:real_hd] - stats[:used_hd]
    m.reply 'Cloud Statistics for ' + conf[:abiquo][:host].upcase
    m.reply "Hypevisors:        #{stats[:hypervisors]}"
    m.reply "Available CPUs:    #{stats[:available_cpus]}"
    m.reply "Total RAM:         #{stats[:real_ram].megabytes.to.gigabytes} GB"
    m.reply "Free RAM:          #{stats[:free_ram].megabytes.to.gigabytes} GB"
    m.reply "Used RAM:          #{stats[:used_ram].megabytes.to.gigabytes} GB"
    m.reply "Total HD:          #{stats[:real_hd]} GB"
    m.reply "Free HD:           #{stats[:free_hd]} GB"
    m.reply "Used HD:           #{stats[:used_hd]} GB"
  end

  on :message, /!deploy (.*)/ do |m|
    if not AbiquoDeployer.authorized?(m.user.nick)
      m.reply "I'm sorry folk, you are not authorized to deploy"
    else
      AbiquoDeployer.client = m
      AbiquoDeployer.deploy
    end
  end
  
  on :message, /!list vms (.*)/ do |m, query|
    #require 'pp'
    AbiquoDeployer.list_vms(:host => query)
    #m.reply "#{vm.name} #{vm.memory_size}"
    #rescue Exception => e
    #  m.reply "** Error when talking to the hypervisor"
    #end
  end
  
  #on :message, /eval (.*)/ do |m, query|
  #  begin
  #  rs = ControlWS
  #  eval query
  #  rescue SyntaxError
  #end
end

EM.run {bot.start}
