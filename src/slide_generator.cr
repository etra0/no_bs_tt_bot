require "http"
require "http/client"

module NoBullshitBot
  struct Slideshow
    @images : Array(String)
    @audio : String

    def initialize(response)
      @images = response["picker"].as_a.map &.["url"].as_s
      @audio = response["audio"].as_s
    end

    def build_video : File
      files = Array(File).new

      @images.each do |img|
        tf = File.tempfile(".jpg") do |f|
          HTTP::Client.get img do |response|
            IO.copy(response.body_io, f)
          end
        end
        files << tf
      end

      audio = File.tempfile(".mp3") do |f|
        HTTP::Client.get @audio do |response|
          IO.copy(response.body_io, f)
        end
      end

      return Slideshow.encode_video(files, audio)
    end

    def self.get_duration(f : File)
      buffer = IO::Memory.new
      Process.run("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", f.path], output: buffer)
      return buffer.to_s.to_f
    end

    def self.shortest_media(video : File, audio : File) : Symbol
      audio_dur = Slideshow.get_duration(audio)
      video_dur = Slideshow.get_duration(video)

      if audio_dur < video_dur
        return :audio
      end

      return :video
    end

    def self.encode_video(urls : Array(File), audio : File) : File
      first_video_enc = File.tempfile(".mp4")
      first_video_enc.close
      args = Array(String).new
      urls.each { |u| args.concat(["-loop", "1", "-t", "3", "-i", u.path]) }

      args.concat ["-stream_loop", "-1", "-i", audio.path]
      args << "-filter_complex"

      last_out = "[img0]"
      filter = String.build do |str|
        # First we're going to rescale all images.
        0.upto(urls.size - 1) do |i|
          str << "[#{i}]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1,setsar=1,format=yuv420p[img#{i}]; "
        end

        # Join all images doing a transition slideleft.
        1.upto(urls.size - 1) do |i|
          str << last_out
          str << "[img#{i}]xfade=transition=slideleft:duration=0.5:offset=#{(2.5 * i)}"
          last_out = "[f#{i - 1}]"
          str << last_out
          str << ";"
        end
      end
      args << filter.chomp(';')
      args.concat ["-map", last_out, "-r", "25", "-pix_fmt", "yuv420p", "-c:v", "libx264", "-an", "-y", first_video_enc.path]
      Process.run("ffmpeg", args, error: Process::Redirect::Inherit)

      final_video = File.tempfile(".mp4")
      final_video.close
      case Slideshow.shortest_media(first_video_enc, audio)
      when :audio
        Process.run("ffmpeg", ["-i", first_video_enc.path, "-stream_loop", "-1", "-i", audio.path, "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-shortest", "-y", final_video.path], error: Process::Redirect::Inherit)
      when :video
        Process.run("ffmpeg", ["-stream_loop", "-1", "-i", first_video_enc.path, "-i", audio.path, "-shortest", "-fflags", "shortest", "-max_interleave_delta", "100M", "-map", "0:v:0", "-map", "1:a:0", "-c:v", "libx264", "-y", final_video.path], error: Process::Redirect::Inherit)
      end

      # Clean the other files.
      urls.each &.delete
      audio.delete
      first_video_enc.delete
      return final_video
    end
  end
end
