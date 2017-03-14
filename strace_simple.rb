#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#　↓　変数などの初期設定：開始　↓
  require 'timeout'
  require 'open3'
  require 'time'
  $hash = Hash.new
  $all = 0

  #プログラムの実行開始時刻
  $now_time = Time.new.strftime("%Y-%m-%d")

  #rsyslogdのプロセスIDを取得
  $target_pid = `pidof rsyslogd`.chomp #10
  str = `ls -l /proc/#{$target_pid}/fd`

  #ファイル出力先
  #$verification_strace_All_Line = "./strace_simple_All_" + Time.new.strftime("%Y-%m-%d") + ".log"
  $verification_strace_All_Line = "./strace_simple_all.log"
  $verification_strace_1_Line = "./strace_simple_one.log"

  #ファイルと内容を指定して書き込む
  def writefile_a(file,msg)
    File.open(file,"a") do |out|
        #if msg =~ /^\[pid/ || /(?!SIGH)/
        if msg =~ /^\[pid/
          if msg =~ /yasuudao|julis|tsuge143|S|mendamenda|ryougoPC|Asteria|delver|logger/
            out.puts msg
          end
        end
    end
  end

  def writefile2(file,msg)
    File.open(file,"a") do |out|
          out.puts msg
    end
  end

  def writefile_w(file,msg)
    File.open(file,"w") do |out|
      #if msg =~ /^\[pid/ || /(?!SIGH)/
      if msg =~ /^\[pid/
        if msg =~ /yasuudao|julis|tsuge143|S|mendamenda|ryougoPC|Asteria|delver|logger/
          out.puts msg
        end
      end
    end
  end

  def writefile2_a(file,msg)
    File.open(file,"w") do |out|
        out.puts msg
    end
  end
#　↑　変数などの初期設定：完了　↑

#　必要なファイルの作成
writefile_a($verification_strace_All_Line,str)
writefile2("#{$verification_strace_All_Line}.csv","Time,Sum,Count,Sentence")
writefile_w($verification_strace_1_Line,str)
writefile2_a("#{$verification_strace_1_Line}.csv","Time,Sum")

def main
  p "しばらくお待ちくださいませ。"
  interval = 60
  stdin, stdout, stderr, wait_thr = Open3.popen3("strace -t -f -e trace=write,sendto -s 100000 -p #{$target_pid}")
  stdin.close
  sleep_time = interval - (Time.new.to_i%interval) #30
  sleep(sleep_time)
    loop do
      begin
        timeout  = interval - (Time.new.to_i%interval)
        start_at = Time.new.strftime("%H:%M:%S")
        Timeout.timeout(timeout) do
          loop do
            select([stderr])
            line = stderr.gets
            writefile_a($verification_strace_All_Line,line)
            writefile_w($verification_strace_1_Line,line)
            File.foreach($verification_strace_1_Line) do |line|
              $log = line
              msg = line.split
              msg[2] =~ /(\d+:\d+:\d+)/
              cur_time = $1
              line =~ /\w+\(\d+,\s"(.+)"/
              next if $1.nil?
              if $1.nil?
                next
              end
              count = $1.split("\\n").length
                if $hash.has_key?(cur_time)
                  $hash[cur_time] += count
                else
                  $hash[cur_time] = count
                end
              $all = $all + count
              $then = count

              #cur_time = 現在時刻（時：分：秒）
              #$all = 出力したログの累積値
              #$then = その瞬間、ログを出力した数
              #$log =　出力したログの内容
              #now_time = 現在時刻（年-月-日）

              writefile2("#{$verification_strace_All_Line}.csv","#{cur_time},#{$all},#{$then},#{$log}")
              $now_time = Time.new.strftime("%Y-%m-%d")
              writefile2_a("#{$verification_strace_1_Line}.csv","#{$now_time} #{cur_time},#{$all},#{$then}")
            end
          end
        end

      #日付が変わったらファイル名を変更する
      rescue Timeout::Error
        if start_at =~ /00:00:\d+/
          #$verification_strace_All_Line = "./firstaid/strace_L_All_" + Time.new.strftime("%Y-%m-%d") + ".log"
          #$verification_strace_1_Line = "./firstaid/strace_simple_" + Time.new.strftime("%Y-%m-%d") + ".log"
	      end
      end

      p "#{Time.new}　までのログを出力しました。"
    end
end

if __FILE__ == $PROGRAM_NAME
  main
end
