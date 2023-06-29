require "uri"
require "http/client"
require "json"

module NoBullshitBot
  class CobaltAPI
    @headers = HTTP::Headers {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }

    def initialize(@base_url = "co.wuk.sh")
      @client = HTTP::Client.new(@base_url, tls: true)
    end

    def handle_stream(inp) : File
      puts "Downloading file..."
      file_handle = File.tempfile(".mp4") do |f|
        HTTP::Client.get(inp) do |response|
        # TODO: Search for a better way to make a buffered copy.
          while IO.copy(response.body_io, f, 1024 * 1024) != 0
          end
        end
      end
      return file_handle
    end

    # This will return a tempfile in order to be read by the Telegram Bot.
    # It's the job of the Caller to delete the tempfile.
    def download_video(url : URI) : File
      request = {
        "url": url.to_s,
        "isNoTTWatermark": true
      }

      response = @client.post("/api/json", body: request.to_json, headers: @headers)
      response = JSON.parse(response.body)
      status = response["status"].as_s
      if status == "error" 
        raise "Couldn't query the api: #{response["text"].as_s}"
      end
      
      case status
      when "stream"
        return self.handle_stream response["url"].as_s
      else
        raise "Don't know how to handle this yet"
      end
    end

  end
end
