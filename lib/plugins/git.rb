require 'cinch'

module Plugins
    class GitDude
  include Cinch::Plugin

 # timer 5, method: :new_stuff
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

end 
