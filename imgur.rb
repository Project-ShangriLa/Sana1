require 'net/http'
require 'uri'
require 'json'
require "httpclient"

class Imgur
  
  URL = "https://api.imgur.com/3/image"
  
  def initialize(client_id)
    @client_id = client_id
  end
  
  def anonymous_upload(file_path)
    auth_header = { 'Authorization' => "Client-ID " + @client_id }

    http_client = HTTPClient.new
    
    File.open(file_path) do |file|
      body = { 'image' => file }
      @res = http_client.post(URI.parse(URL), body, auth_header)
    end

    result_hash = JSON.load(@res.body)
    return result_hash["data"]["link"]
  end
   
    
end