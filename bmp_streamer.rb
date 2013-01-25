$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
require "bmp_image"
require "raw_video_encoder"

input = ARGV[0]
output = ARGV[1]
quality = (ARGV[2] || "50").to_i

unless input and output
  puts "$0 input_folder output_file [quality]\n"
  puts "    output may be '-' for stdout; 0 < quality <= 100"
  exit
end

bmps = Dir["#{File.expand_path(input)}/*.bmp"].sort.map do |file|
  BMPImage.new(file)
end
raise "No bitmaps found in #{input}" if bmps.size == 0

IO.popen("mplayer -demuxer rawvideo -rawvideo w=640:h=480:format=rgb24:fps=25 -", "w") do |io|
  coder = RgbVideoEncoder.new(io, bmps)
  loop do
    coder.encode(quality)
  end
end
