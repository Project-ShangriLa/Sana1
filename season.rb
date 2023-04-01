require 'net/http'
require 'uri'
require 'json'

BASE_YEAR = 2014
ANIME_API_URL = "https://api.moemoe.tokyo/anime/v1/master"

def gen_cours_name(cours_id)
  season_ja_list = ['秋期','冬期','春期', '夏期']
  season_ja_list[cours_id % 4]
end

def gen_cours_name_en(cours_id)
  season_ja_list = ['autumn','winter','spring','summer']
  season_ja_list[cours_id % 4]
end

def gen_year(cours_id)
  year = BASE_YEAR + ((cours_id - 1) / 4)
  year.to_s
end

def gen_graph_filename(cours_id)
  gen_year(cours_id) + '_' + gen_cours_name_en(cours_id)
end

# 2019年 夏期 アニメ公式 フォロワー数 // 元のベタ書き
# 2019年 夏期 アニメ公式 フォロワー数 // この関数で出力
def gen_cours_title(cours_id)
  "#{gen_year(cours_id)}年 #{gen_cours_name(cours_id)} アニメ公式 フォロワー数"
end

def gen_cours_title_en(cours_id)
  "#{gen_cours_name_en(cours_id).capitalize} #{gen_year(cours_id)} Anime Twitter Followers"
end

def cours_id2_apiurl(cours_id)
  year = BASE_YEAR + ((cours_id - 1) / 4)
  season = (cours_id % 4)
  season = 4 if season == 0
  "#{ANIME_API_URL}/#{year}/#{season}"
end


def build_graph_anime_data(cours_id)
  url = cours_id2_apiurl(cours_id)

  result = Net::HTTP.get(URI.parse(url))
  result_hash = JSON.load(result)

  account_list = []
  account_hash ={}

  result_hash.each do |record|
    account_list.push record["twitter_account"]
    account_hash[record["twitter_account"]] = {}
    account_hash[record["twitter_account"]][:id] = record["id"]
    account_hash[record["twitter_account"]][:title] = record["title"]
    account_hash[record["twitter_account"]][:title_short1] = record["title_short1"]
    account_hash[record["twitter_account"]][:title_en] = record["title_en"]
    account_hash[record["twitter_account"]][:twitter_hash_tag] = record["twitter_hash_tag"]
    account_hash[record["twitter_account"]][:sequel] = record["sequel"]
  end

  return account_list, account_hash
end