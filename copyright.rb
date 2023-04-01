require 'RMagick'
#http://www.mk-mode.com/octopress/2013/08/28/ruby-write-character-by-rmagick/
require 'date'

now_year = Date.today.year
# メッセージ
MSG_USAGE     = "USAGE: ruby write_copyright.rb filename"
MSG_NOT_EXIST = "File not exist!"
# フォント（存在するフォントファイルを指定する）
FONT =  './freefont/NotoSansCJKjp-Medium.otf'
# 描画文字列
OUT_STR = "©2014-#{now_year} @anime_follower by Anime API. (Batch Ver 230326) https://note.com/akb428"

class Arg
  # 引数取得
  def get_arg
    begin
      if ARGV[0]
        # ファイルが存在しなければ終了
        unless File.exist?(ARGV[0])
          puts MSG_NOT_EXIST + " #{ARGV[0]}"
          exit
        end
      else
        # 引数無ければ終了
        puts MSG_USAGE
        exit
      end

      # ファイル名返却
      return ARGV[0]
    rescue => e
      STDERR.puts "[ERROR][#{self.class.name}.get_arg] #{e}"
      exit 1
    end
  end
end

class WriteCopyright
  def initialize(filename)
    @img_file = filename
  end

  # Copyright 描画
  def write_copyright
    #FileUtils.cp(@img_file, @img_file + ".org", {:preserve => true})  # 元画像退避
    img  = Magick::ImageList.new(@img_file)  # 画像オブジェクト
    draw = Magick::Draw.new                  # 描画オブジェクト

    begin
      # 文字の影 ( 1pt 右下へずらす )
      draw.annotate(img, 0, 0, 4, 4, OUT_STR) do
        self.font      = FONT                      # フォント
        self.fill      = 'black'                   # フォント塗りつぶし色(黒)
        self.stroke    = 'transparent'             # フォント縁取り色(透過)
        self.pointsize = 16                        # フォントサイズ(16pt)
        self.gravity   = Magick::SouthWestGravity  # 描画基準位置(右下)
      end

      # 文字
      draw.annotate(img, 0, 0, 5, 5, OUT_STR) do
        self.font      = FONT                      # フォント
        self.fill      = 'white'                   # フォント塗りつぶし色(白)
        self.stroke    = 'transparent'             # フォント縁取り色(透過)
        self.pointsize = 16                        # フォントサイズ(16pt)
        self.gravity   = Magick::SouthWestGravity  # 描画基準位置(右下)
      end

      # 画像生成
      img.write(@img_file)
    rescue => e
      STDERR.puts "[ERROR][#{self.class.name}.write_copyright] #{e}"
      exit 1
    end
  end
end

# 引数取得
#obj_arg = Arg.new
#filename = obj_arg.get_arg

