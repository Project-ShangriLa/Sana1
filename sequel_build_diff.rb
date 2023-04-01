require "sequel"

DB = Sequel.mysql2('anime_admin_development', :host => ENV['SANA_DB_HOST'], :user => ENV['SANA_DB_USER'], :password => ENV['SANA_DB_PASSWORD'], :port => '3306')

#タイトルをキーにハッシュタグを取得できるハッシュを返す
def build_hash_tag_map (cours_id, title_cut_size, lang)
  title_column = lang == 'en' ? :title_en : :title
  bases = DB[:bases].where(:cours_id => cours_id).select(title_column, :twitter_hash_tag).all
  result_map = {}
  bases.each do |base|
    title = base[title_column]
    adjust_title = title.length > title_cut_size + 1 ? title[0, title_cut_size] + '~' : title
    result_map[adjust_title] = base[:twitter_hash_tag]
  end
  result_map
end

def build_past_follower_sql(ids, past_hours)
  past_follower_sql = <<EOS
SELECT bases_id,follower,get_date FROM twitter_status_histories WHERE
bases_id IN (#{ids.join(',')}) AND
get_date
between date_add(date(now()), interval - #{past_hours} hour) and date_format(now(), '%Y.%m.%d') order by get_date LIMIT #{ids.length};
EOS

  puts past_follower_sql
  past_follower_sql
end

def build_date_diff_data(cours_id, target_past_hours, lang = 'ja')

  title_column = lang == 'en' ? :title_en : :title
  bases = DB[:bases].where(:cours_id => cours_id).select(:id, title_column).all

  ids = []
  title_map = {}
  bases.each do |base|
    ids.push(base[:id])
    title_map[base[:id]] = base[title_column]
  end

  follower_diff = {}

  DB.fetch(build_past_follower_sql(ids, target_past_hours)) do |row|
    follower_diff[row[:bases_id]] = row[:follower]
  end

  p follower_diff

  twitter_status = DB[:twitter_statuses].where(:bases_id => ids).select(:bases_id, :follower).all

  diff_result = {}
  twitter_status.each do |tw_status|
    next if follower_diff[tw_status[:bases_id]].nil?
    diff_result[title_map[tw_status[:bases_id]]] = tw_status[:follower] - follower_diff[tw_status[:bases_id]]
  end

  #p diff_result

  diff_result.each do |title, diff|
    puts title + "=>" + diff.to_s
  end

  #ハッシュソート
  diff_result.sort { |(k1, v1), (k2, v2)| v2 <=> v1 }

end

