require "./spec_helper"

describe NoBullshitBot do
  # TODO: Write tests

  it "Can query cobalt API" do
    api = NoBullshitBot::CobaltAPI.new
    ch = Channel(Nil).new
    spawn(name: "vid1") do
      url = URI.parse "https://vm.tiktok.com/ZM2PgqMku/"
      puts api.download_video(url).path
      ch.send(nil)
    end

    spawn(name: "vid2") do
      url = URI.parse "https://vm.tiktok.com/ZM2PSC3Wy/"
      puts api.download_video(url).path
      ch.send(nil)
    end

    2.times { ch.receive }
    true.should eq(true)
  end
end
