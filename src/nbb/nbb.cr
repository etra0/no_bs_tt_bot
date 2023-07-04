require "tourmaline"
require "dotenv"
require "../cobalt"

module NoBullshitBot
  if !ENV["BOT_TOKEN"]?
    Dotenv.load ".env"
  end

  def self.start_bot
    client = Tourmaline::Client.new(ENV["BOT_TOKEN"])
    api = NoBullshitBot::CobaltAPI.new

    tiktok_handler = Tourmaline::HearsHandler.new(/^https:\/\/(vm|www)\.tiktok\.com/) do |ctx|
      text = ctx.text(strip_command: false).to_s
      next if text.empty?

      link = text.split(" ")[0]
      
      spawn do
        begin
          f = api.download_video link
          ctx.reply_with_video f.path
          f.delete
        rescue ex
          puts "Couldn't get the video: #{ex.message}"
        end
      end
    end

    client.register(tiktok_handler)

    client.poll
  end
end
