require 'net/http'
require 'uri'
require 'json'
require 'active_support'
require "httpclient"
require 'date'
require "./twitter.rb"
require "./grapics_for_diff.rb"
require "./copyright.rb"
require "./imgur.rb"
require "./season.rb"
require 'optparse'
require './sequel_build_diff.rb'
require "./s3upload.rb"

@cours_id = nil
@twitter_flag = true
@diff_days = false
@diff_hours = 0
@title_cut_size = 20
@lang = 'ja'

opt = OptionParser.new
Version = "1.0.0"
opt.on('-c COURS_ID', 'cours_id') {|v| @cours_id = v }
opt.on('-n', 'not tweet') {@twitter_flag = false}
opt.on('-h hour', 'diff_days') {|v| @diff_hours = v }
opt.on('-f from yyyymmdd', 'from diff_days') {|v| @from_date = v }
opt.on('-l LANG', 'language') {|v| @lang = v }
opt.on('-t TITLE_CUT_SIZE', 'title cut size') {|v| @title_cut_size = v.to_i }
opt.parse!(ARGV)

get_time = Time.now

if @from_date.present?
  base_day = Date.parse(@from_date)
  now_day = Date.today
  total_day = now_day - base_day
  @diff_hours = total_day.to_i * 24
  @diff_hours = @diff_hours.to_s
end

p @diff_hours

@diff_days = @diff_hours.to_i.div(24)

end_fix = '日前'
@tw_end_fix = '日'

if @diff_hours.to_i < 24
 @diff_days = @diff_hours
 end_fix = '時間前'
 @tw_end_fix = '時'
end

cours_id = @cours_id.to_i
graph_title = gen_cours_title(cours_id)
graph_title = graph_title + "(期間増加分) 現在-#{@diff_days}" + end_fix

if @lang == 'en'
  # (increase) 7 days
  graph_title = gen_cours_title_en(cours_id) + "(increase) #{@diff_days} days"
end

@hash_tag_map = build_hash_tag_map(cours_id, @title_cut_size, @lang)
TITLE_LIMIT = 40

IMAGE_BUCKET_NAME = 'sana-diff-image'

cours_graph_filename = gen_graph_filename(cours_id)
@cours_name = gen_cours_name(cours_id)
GRAPICS_FONT_SIZE = 10

File.open './conf/conf.json' do |file|
  conf = JSON.load(file.read)
  @imgur_conf = conf["imgur"]
end

sorted_graphics_data = build_date_diff_data(cours_id, @diff_hours, @lang)

graph_data = []
graph_label = {} 
label_counter = 0
sorted_graphics_data.each{|key, value|
  graph_data.push value
  graph_label[label_counter] = key.length > @title_cut_size + 1 ? key[0, @title_cut_size] + '~' : key
  label_counter+=1
}

#グラフ作成
#TODO
#単純にグラフ生成だけに絞る、無理してrubyで作らなくていいのでpythonとかJavaも検討する

filename_base = cours_graph_filename + "_anime_";

filename = draw_grahics(graph_data.take(TITLE_LIMIT), graph_label, filename_base , get_time, graph_title , GRAPICS_FONT_SIZE, graph_data[0], @lang)
puts filename
#exit
# Copyright 描画
WriteCopyright.new(filename).write_copyright

#p @hash_tag_map
@index = 0
def build_status(graph_label)
  #TODO 英語版の時 差分1日以下の時表記がおかしくなる
  status = ""
  if @lang == 'en'
    name = @new_title_only ? gen_cours_name_en(@cours_id.to_i) + "(Not sequel)": gen_cours_name_en(@cours_id.to_i)
    status = sprintf("#{name}[Ranking] Anime Twitter Followers (increase #{@diff_days} days) No%s=%s No%s=%s #%s #%s",
      @index+1, graph_label[@index], @index+2, graph_label[@index+1],
      @hash_tag_map[graph_label[@index]],@hash_tag_map[graph_label[@index+1]]) 
    puts status
    puts status.length 
    if status.length >= 120
      puts "120 + URL => 140 Length Over Adjust!"
      status = sprintf("#{name} [Ranking] Anime Twitter Followers(increase #{@diff_days} days) No%s=%s #%s",
        @index+1, graph_label[@index], @hash_tag_map[graph_label[@index]])
      puts status
    end
  else 
    name = @new_title_only ? @cours_name + "(新作のみ)": @cours_name
    status = sprintf("#{name}のアニメ公式フォロワー数期間増加ランキング(#{@diff_days}#{@tw_end_fix}間)は %s位=%s %s位=%s です。#%s #%s",
      @index+1, graph_label[@index], @index+2, graph_label[@index+1],
      @hash_tag_map[graph_label[@index]],@hash_tag_map[graph_label[@index+1]]) 
    puts status
    puts status.length 
    if status.length >= 120
      puts "120 + URL => 140 Length Over Adjust!"
      status = sprintf("#{name}のアニメ公式フォロワー数期間増加ランキング(#{@diff_days}#{@tw_end_fix}間)は %s位=%s です。#%s",
        @index+1, graph_label[@index], @hash_tag_map[graph_label[@index]])
      puts status
    end
  end

  @index += 2
  return status
end

unless(@twitter_flag)
  build_status(graph_label)
  build_status(graph_label)

  s3_filename = @diff_hours + "_" + File.basename(filename)
  s3_upload(IMAGE_BUCKET_NAME, filename, s3_filename)

  exit
end

@tw.update_with_media(build_status(graph_label), File.new(filename))

sleep(3)

#3位、4位
@tw.update_with_media(build_status(graph_label), File.new(filename))

#imgur upload(imgurだとブラウザのTwitterのタイムラインで画像化されないっぽい)
#uploaded_link = Imgur.new(@imgur_conf["client_id"]).anonymous_upload(filename)
#puts uploaded_link  
#@tw.update("アニメフォロワー数期間増加ランキング(#{@diff_days}日間) imgur版 "  +  Time.now.strftime("%Y-%m-%d %H:%M:%S")  + " " + uploaded_link)

#s3_filename = @diff_hours + "_" + File.basename(filename)
#s3_upload(IMAGE_BUCKET_NAME, filename, s3_filename)
