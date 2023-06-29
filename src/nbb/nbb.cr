require "tourmaline"
require "dotenv"
require "../cobalt"

module NoBullshitBot
  Dotenv.load ".env"

  def self.start_bot
    puts ENV["BOT_TOKEN"]
    client = Tourmaline::Client.new(ENV["BOT_TOKEN"])
    api = NoBullshitBot::CobaltAPI.new

    tiktok_handler = Tourmaline::HearsHandler.new(/^https:\/\/vm\.tiktok\.com/) do |ctx|
      next if !ctx.message
      next if !ctx.message.not_nil!.text

      text = ctx.message.not_nil!.text.to_s
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
