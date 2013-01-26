require "quality_control"

class RawVideoEncoder
  def initialize(path_or_io, frames, colors=:rgb)
    unless [:rgb, :yuv].include? colors
      raise "Only :yuv and :rgb are valid colors"
    end
    @colors = colors
    @frames = frames

    case path_or_io
    when String
      @io = File.open(path_or_io, "wb")
    when IO
      @io = path_or_io
    else
      raise "String or IO required"
    end

    extend QualityControl
  end

  def encode(quality)
    @quality = quality
    @quality = 100 if @quality > 100
    @quality = 1 if @quality < 1

    @frames.each do |frame|
      quality_control do
        encode_frame(frame)
      end
    end
  end

  def encode_frame(frame)
    skip = (frame.height / 64 * ((100 - @quality).to_f / 100.0)).to_i
    skip = 1 if skip < 1
    y = 0
    buf = ""

    while y + skip < frame.height
      line = ""
      x = 0
      pos = y * frame.width

      while x + skip < frame.width
        line << pixel_triple_at(frame, pos, @colors) * skip
        x += skip
        pos += skip
      end
      line << pixel_triple_at(frame, pos, @colors) * (frame.width - x)
      buf << line * skip
      y += skip
    end
    buf << line * (frame.height - y)

    @io << buf
  end

  def pixel_triple_at(frame, pos, colors)
    send("#{colors}_triple_at", frame, pos)
  end

  def yuv_triple_at(frame, pos)
    r, g, b = frame.rgb_triple_at(pos, :reverse)
    y = 0.299 * r + 0.587 * g + 0.114 * b
    u = -0.1687 * r - 0.3313* g + 0.5 * b + 128
    v = 0.5 * r - 0.4187 * g - 0.813 * b + 128
    [y, u, v].pack("CCC")
  end

  def rgb_triple_at(frame, pos)
    frame.rpixel_at(pos)
  end
end

class YuvVideoEncoder < RawVideoEncoder
  def initialize(path_or_io, frames)
    super(path_or_io, frames, :yuv)
  end
end

class RgbVideoEncoder < RawVideoEncoder
  def initialize(path_or_io, frames)
    super(path_or_io, frames, :rgb)
  end
end
