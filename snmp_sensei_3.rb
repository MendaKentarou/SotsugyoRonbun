#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'snmp'
require "time"

INTERVAL = 60
FN       = [54, 56, 61, 66, 71, 242, 81, 86, 10]
SUM      = [54, 56, 61, 66, 71, 242, 81, 86, 10]
LOST     = [0, 0, 0, 0, 0, 0, 0, 0, 0]
RESEND   = [0, 0, 0, 0, 0, 0, 0, 0, 0]
hash     = Hash.new
resend_count = 0
c = 0

#メモ：各ホストのIPアドレス
name2ip = {}
name2ip["yasuudao"]   = "192.168.1.54"
name2ip["julis"]      = "192.168.1.56"
name2ip["tsuge143"]   = "192.168.1.61"
name2ip["S"]          = "192.168.1.66"
name2ip["mendamenda"] = "192.168.1.71"
name2ip["ryougoPC"]   = "192.168.1.242"
name2ip["Asteria"]    = "192.168.1.81"
name2ip["delver"]     = "192.168.1.86"
name2ip["logger"]     = "192.168.1.10"
all_host              = name2ip.values
#all_host = ["192.168.1.54","192.168.1.56","192.168.1.61","192.168.1.66","192.168.1.71","192.168.1.242","192.168.1.81","192.168.1.86","192.168.1.10"]

#コミュニティ名
name_com = "tsunolab"

#OID名 getTimeCount
oid_1 = "1.3.6.1.4.1.8072.1.3.2.4.1.2.12.103.101.116.84.105.109.101.67.111.117.110.116.1"
oid_2 = "1.3.6.1.4.1.8072.1.3.2.4.1.2.13.103.101.116.84.105.109.101.67.111.117.110.116.50.1"

#ファイル名
file_name = []
all_host.each do |ip|
  last_octet = ip.split('.')[-1]
  #file_name << "all_host_csv/host_#{last_octet}.csv"
  file_name << "h#{last_octet}"
end

#file_name_1 = "all_host_csv/host_54.csv", file_name_2 = "all_host_csv/host_56.csv"
#file_name_3 = "all_host_csv/host_61.csv", file_name_4 = "all_host_csv/host_66.csv"
#file_name_5 = "all_host_csv/host_71.csv", file_name_6 = "all_host_csv/host_242.csv"
#file_name_7 = "all_host_csv/host_81.csv", file_name_8 = "all_host_csv/host_86.csv"
#file_name_9 = "all_host_csv/host_10.csv", file_name_10 = "all_host_csv/host_all.csv"

def write_file(file,msg)
  File.open(file,"a") do |out|
    out.puts msg
  end
end

i = 0

#ここから実行するところ
managers = {}
all_host.each do |ip|
  managers[ip] = SNMP::Manager.new(:Host => ip, :Community => name_com)
end

loop do
  sleep_time = INTERVAL - (Time.now.to_i%INTERVAL)
  p "wait a minutes..."
  sleep(sleep_time)

  p "Start monitoring at #{Time.now}"
  get_results = {}
  for ip in all_host do
    c = c + 1
    manager = managers[ip]
    if c <= 9
      get_results[ip] = manager.get_value(oid_1).to_s
      if get_results[ip] == ""
        until get_results[ip] != ""
          RESEND[i] = RESEND[i] + 1
          resend_count = resend_count + 1
          genzai = Time.new.strftime("%Y-%m-%d,%H:%M:%S")
          write_file("#{file_name}_lost.csv","#{genzai}")
          managers[ip] = SNMP::Manager.new(:Host => ip, :Community => name_com)
          get_results[ip] = manager.get_value(oid_1).to_s
        end
      end
      p get_results[ip]

      time_IP_count = get_results[ip]
      p "1行目　ホストIP:#{FN[i]}　取得:#{time_IP_count}"
      if time_IP_count != ""
        now_time_IP_count_2 = time_IP_count.split(" ")
        now_time_IP_count_3 = now_time_IP_count_2[1].split(",")
        now_time_IP_count_3[0] =~ /(\d+:\d+:\d+)/
        now_minutes_s_1 = $1
        now_time_IP_count_3[0] =~ /(\d+:\d+):\d+/
        now_minutes_s_2 = $1
        now_time_count = now_time_IP_count_2[0].to_s + "," + now_minutes_s_1 + "," + now_minutes_s_2.to_s + "," + now_time_IP_count_3[1].to_s #+ "," + now_time_IP_count_3[2].to_s
        p "2行目　ホストIP:#{FN[i]}　取得:#{now_time_count} 累計損失回数:#{LOST[i]} 累計再送回数:#{RESEND[i]} 瞬間再送回数:#{resend_count}"
        write_file("#{file_name[i]}_write.csv",now_time_count)
        SUM[i] = now_time_IP_count_3[1].to_s
        resend_count = 0
      elsif time_IP_count == ""
        LOST[i] = LOST[i] + 1
        genzai = Time.new.strftime("%Y-%m-%d,%H:%M:%S")
        p "3行目　ホストIP:#{FN[i]}　時刻:#{genzai} ※　ログが損失　※"
      end

      if i < 8
        i = i + 1
      end

    if c == 9
        get_results[ip] = manager.get_value(oid_2).to_s
        if get_results[ip] == ""
          until get_results[ip] != ""
            RESEND[i] = RESEND[i] + 1
            resend_count = resend_count + 1
            genzai = Time.new.strftime("%Y-%m-%d,%H:%M:%S")
            write_file("#{file_name}_lost.csv","#{genzai}")
            managers[ip] = SNMP::Manager.new(:Host => ip, :Community => name_com)
            get_results[ip] = manager.get_value(oid_2).to_s
          end
        end
        p get_results[ip]

        time_IP_count = get_results[ip]
        p "1行目　ホストIP:#{FN[i]}　取得:#{time_IP_count}"
        if time_IP_count != ""
          now_time_IP_count_2 = time_IP_count.split(" ")
          now_time_IP_count_3 = now_time_IP_count_2[1].split(",")
          now_time_IP_count_3[0] =~ /(\d+:\d+:\d+)/
          now_minutes_s_1 = $1
          now_time_IP_count_3[0] =~ /(\d+:\d+):\d+/
          now_minutes_s_2 = $1
          now_time_count = now_time_IP_count_2[0].to_s + "," + now_minutes_s_1 + "," + now_minutes_s_2.to_s + "," + now_time_IP_count_3[1].to_s #+ "," + now_time_IP_count_3[2].to_s
          p "2行目　ホストIP:#{FN[i]}　取得:#{now_time_count} 累計損失回数:#{LOST[i]} 累計再送回数:#{RESEND[i]} 瞬間再送回数:#{resend_count}"
          write_file("#{file_name[i]}_single_write.csv",now_time_count)
          SUM[i] = now_time_IP_count_3[1].to_s
          resend_count = 0
        elsif time_IP_count == ""
          LOST[i] = LOST[i] + 1
          genzai = Time.new.strftime("%Y-%m-%d,%H:%M:%S")
          p "3行目　ホストIP:#{FN[i]}　時刻:#{genzai} ※　ログが損失　※"
        end

        if i == 8
          i = 0
          while i <= 7
            p SUM[i]
            i = i + 1
          end
            p SUM[8]
            SUM[100] = 0
            SUM[100] = SUM[1].to_i + SUM[2].to_i + SUM[3].to_i + SUM[4].to_i + SUM[5].to_i + SUM[6].to_i + SUM[7].to_i + SUM[8].to_i
            p SUM[100]
          puts ""
          i = 0
        end

      end
    end
  end
  c = 0
end
