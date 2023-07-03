require "http"
require "http/client"

module NoBullshitBot
  class Slideshow
    @images : Array(String)
    @audio : String

    def initialize(response)
      @images = response["picker"].as_a.map &.["url"].as_s
      @audio = response["audio"].as_s
    end

    def build_video : File
      tempfile = File.tempfile
      files = Array(File).new

      @images.each do |img|
        tf = File.tempfile(".jpg") do |f|
          HTTP::Client.get img do |response|
            while IO.copy(response.body_io, f, 1024 * 1024) != 0
            end
          end
        end
        files << tf
      end

      audio = File.tempfile(".mp3") do |f|
        HTTP::Client.get @audio do |response|
          while IO.copy(response.body_io, f, 1024 * 1024) != 0
          end
        end
      end

      return Slideshow.encode_video(files, audio)
    end

    def self.encode_video(urls : Array(File), audio : File) : File
      tf = File.tempfile(".mp4")
      args = Array(String).new
      urls.each { |u| args.concat(["-loop", "1", "-t", "3", "-i", u.path]) }

      args.concat ["-stream_loop", "-1", "-i", audio.path]
      args << "-filter_complex"
      
      last_out = "[img0]"
      filter = String.build do |str|
        # First we're going to rescale all images.
        0.upto(urls.size() - 2) do |i|
          str << "[#{i}]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1,setsar=1,format=yuv420p[img#{i}]; "
        end
        1.upto(urls.size() - 2) do |i|
          str << last_out
          str << "[img#{i}]xfade=transition=slideleft:duration=0.5:offset=#{(2.5 * i)}"
          last_out = "[f#{i - 1}]"
          str << last_out
          str << "; "
        end
      end
      args << filter
      args.concat ["-map", last_out, "-r", "25", "-pix_fmt", "yuv420p", "-c:v", "libx264", "-an", "-y", tf.path]
      Process.run("ffmpeg", args, error: Process::Redirect::Inherit)
      tf_final = File.tempfile(".mp4")
      Process.run("ffmpeg", ["-i", tf.path, "-stream_loop", "-1", "-i", audio.path, "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-shortest", "-y", tf_final.path], error: Process::Redirect::Inherit)

      # Clean the other files.
      urls.each &.delete
      audio.delete
      tf.delete
      return tf_final
    end
  end
end
