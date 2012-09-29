$: << File.dirname(__FILE__) + '/../'
require 'rubygems'
require 'cinch' 
require 'webee'
require 'modules/abiquo-deployer'

module Plugins
    class Mothership
        include Cinch::Plugin

        match /mothership abusers/, method: :running_vms, :use_prefix => false
        match /mothership cloud-stats/, method: :cloud, :use_prefix => false

        match /deploy$/, method: :deploy
        match /lista vms\s(.*)/, method: :list_vms
        def initialize(*args)
            super
        end
        def running_vms(m)
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

        def cloud(m)
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

        def deploy(m)
            if not AbiquoDeployer.authorized?(m.user.nick)
              m.reply "I'm sorry folk, you are not authorized to deploy"
            else
              AbiquoDeployer.client = m
              AbiquoDeployer.deploy
        end
      end
  
        def list_vms(m, query)
            AbiquoDeployer.list_vms(:host => query)
      end
    end
end 
