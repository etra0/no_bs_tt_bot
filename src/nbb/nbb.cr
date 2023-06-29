require "tourmaline"
require "dotenv"

module NoBullshitBot
  Dotenv.load ".env"

  def self.start_bot
    puts ENV["BOT_TOKEN"]
    client = Tourmaline::Client.new(ENV["BOT_TOKEN"])

    tiktok_handler = Tourmaline::HearsHandler.new(/^vm\.tiktok\.com/) do |ctx|
      text = ctx.text.to_s
      next if text.empty?

      link, *rest = text.split " "
      puts link
    end

    client.register(tiktok_handler)

    client.poll
  end
end
