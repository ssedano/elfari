module Plugins
  class RimameloPlugin
    include Cinch::Plugin

    def initialize(* arg)
      super
    end

    match /rimamelo (.*)/, method: :rhyme, :use_prefix => false
    def rhyme(m, query)
      on :message, /rimamelo (.*)/ do |m, query|
        uri = "http://rimamelo.herokuapp.com/web/api?model.rhyme=#{URI.escape(query)}"
        rhyme = RestClient.get(uri)
        rhyme["<rhyme>"] = ""
        rhyme["</rhyme>"] = ""
        rhyme["<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"] = ""
        m.reply "#{rhyme}"
        #@elfari_port = ElFari::Config.config[:elfari][:port]
        #@elfari_url = ElFari::Config.config[:elfari][:port]
        #RestClient.post "http://#{@elfari_url}:#{@elfari_port}/say", :text => "#{rhyme}"
      end
    end
  end
end

