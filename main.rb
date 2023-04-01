require 'active_support'
require 'optparse'
require "sequel"
require "./twitter.rb"
require "./grapics.rb"
require "./copyright.rb"
require "./imgur.rb"
require "./season.rb"
require "./s3upload.rb"

@cours_id = nil
@twitter_flag = true
@new_title_only = false
@title_cut_size = 20
@lang = 'ja'

#-oオプションを使わない時、作品数が多すぎるので上位XXに制限する
TITLE_LIMIT = 40

IMAGE_BUCKET_NAME = 'sana-image'

opt = OptionParser.new
Version = "1.0.0"
opt.on('-c COURS_ID', 'cours_id') {|v| @cours_id = v }
opt.on('-nt', 'not tweet') {@twitter_flag = false} # -nt は最後に書くこと
opt.on('-o', 'new title only') {@new_title_only = true}
opt.on('-t TITLE_CUT_SIZE', 'title cut size') {|v| @title_cut_size = v.to_i }
opt.on('-l LANG', 'language') {|v| @lang = v }
opt.parse!(ARGV)

cours_id = @cours_id.to_i

graph_title = @lang == 'en' ? gen_cours_title_en(cours_id)  : gen_cours_title(cours_id)
cours_graph_filename = gen_graph_filename(cours_id)
@cours_name = gen_cours_name(cours_id)
GRAPICS_FONT_SIZE = 10

File.open './conf/conf.json' do |file|
  conf = JSON.load(file.read)
  @imgur_conf = conf["imgur"]
end

account_list, account_hash = build_graph_anime_data(cours_id)

get_time = Time.now

puts get_time

graph_data = []
graph_label = {} 
label_counter = 0
graph_data_hash = {}
tag_hash_for_rank = {}

DB = Sequel.mysql2('anime_admin_development', :host=>ENV['SANA_DB_HOST'], :user=>ENV['SANA_DB_USER'], :password=>ENV['SANA_DB_PASSWORD'], :port=>'3306')

status_rows = []
history_rows = []

def decide_title_lang(account_hash_obj)
  title = account_hash_obj[:title]
  if @lang == 'en'
    title = account_hash_obj[:title_en]
  end
  title
end

@tw.users(account_list).each do |user|

  if @new_title_only && !account_hash[user.screen_name][:sequel].nil? && account_hash[user.screen_name][:sequel] > 0
    puts user.name + "は続編モノのため除外"
    next;
  end

  puts user.name 
  puts user.screen_name
  puts user.followers_count

  cu_time = Time.now
  
  graph_data.push user.followers_count

  #graph_label_tile = account_hash[user.screen_name][:title]
  graph_label_tile = decide_title_lang(account_hash[user.screen_name])
  graph_label_tile = graph_label_tile[0, @title_cut_size] + '〜' if graph_label_tile.length > @title_cut_size+1

  graph_label[label_counter] = graph_label_tile + "(" + user.followers_count.to_s + ")"
  graph_data_hash[graph_label[label_counter]] = user.followers_count
  tag_hash_for_rank[graph_label[label_counter]] = account_hash[user.screen_name][:twitter_hash_tag]

  status_rows << [
      account_hash[user.screen_name][:id].to_i, #bases_id
      user.followers_count.to_i, #follower
      cu_time, #updated_at
  ]

  history_rows << [
      account_hash[user.screen_name][:id].to_i, #bases_id
      user.followers_count.to_i, #follower
      get_time, #get_date
      cu_time, #created_at
      cu_time, #updated_at
  ]

  label_counter+=1
end

status_rows.each do |row|
  base_row = DB[:twitter_statuses].where(:bases_id => row[0]).limit(1)
  if base_row.first
    obj = { bases_id: row[0], follower: row[1], updated_at: row[2] }
    base_row.update(obj)
  else
    # create = update なので row[2]までしかない
    obj = { bases_id: row[0], follower: row[1],  created_at: row[2], updated_at: row[2] }
    table = DB[:twitter_statuses]
    table.insert(obj)
  end
end

DB[:twitter_status_histories].import([:bases_id, :follower, :get_date, :created_at, :updated_at] ,history_rows)

#ソート
sorted = graph_data_hash.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
graph_data = []
graph_label = {} 
label_counter = 0
sorted.each{|key, value|
  graph_data.push value
  graph_label[label_counter] = key
  label_counter+=1
}

if @new_title_only
  new_label_st = @lang == 'en' ? '(Not sequel)' : ' (新作のみ)'
  graph_title = graph_title + new_label_st
end

filename_base = cours_graph_filename+ "_anime_";

filename = draw_grahics(graph_data.take(TITLE_LIMIT), graph_label, filename_base , get_time, graph_title , GRAPICS_FONT_SIZE, graph_data[0], @lang)
puts filename

# Copyright 描画
WriteCopyright.new(filename).write_copyright


@index = 0
def build_status(graph_label, tag_hash_for_rank)
  status = ""
  if @lang == 'en'
    name = @new_title_only ? gen_cours_name_en(@cours_id.to_i) + "(Not sequel)": gen_cours_name_en(@cours_id.to_i)
    status = sprintf("#{name} [Ranking] Anime Twitter Followers No%s=%s No%s=%s #%s #%s",
                     @index+1, graph_label[@index], @index+2, graph_label[@index+1],
                     tag_hash_for_rank[graph_label[@index]],tag_hash_for_rank[graph_label[@index+1]])
  else
    name = @new_title_only ? @cours_name + "(新作のみ)": @cours_name
    status = sprintf("#{name}のアニメ公式フォロワー数ランキングは %s位=%s %s位=%s です。#%s #%s",
    @index+1, graph_label[@index], @index+2, graph_label[@index+1],
    tag_hash_for_rank[graph_label[@index]],tag_hash_for_rank[graph_label[@index+1]])
  end

  puts status
  @index += 2
  return status
end

unless(@twitter_flag)
  build_status(graph_label, tag_hash_for_rank)
  build_status(graph_label, tag_hash_for_rank)

  s3_filename =  File.basename(filename)
  s3_filename = 'new_' + s3_filename if @new_title_only
  s3_upload(IMAGE_BUCKET_NAME, filename, s3_filename)
  exit
end

@tw.update_with_media(build_status(graph_label, tag_hash_for_rank), File.new(filename))

sleep(3)

#3位、4位
@tw.update_with_media(build_status(graph_label, tag_hash_for_rank), File.new(filename))

#imgur upload(imgurだとブラウザのTwitterのタイムラインで画像化されないっぽい)
#uploaded_link = Imgur.new(@imgur_conf["client_id"]).anonymous_upload(filename)
#puts uploaded_link  
#@tw.update("アニメフォロワー数ランキング imgur版 "  +  Time.now.strftime("%Y-%m-%d %H:%M:%S")  + " " + uploaded_link)

#s3_filename =  File.basename(filename)
#s3_filename = 'new_' + s3_filename if @new_title_only
#s3_upload(IMAGE_BUCKET_NAME, filename, s3_filename)



