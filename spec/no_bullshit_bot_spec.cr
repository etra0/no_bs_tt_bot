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


  it "Can build image sequence", tags: "sequence" do
    api = NoBullshitBot::CobaltAPI.new
    url = "https://vm.tiktok.com/ZM2acrr36/"
    puts api.download_video(url).path
  end
end
