require "quality_control"

class RawVideoEncoder
  include QualityControl

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
  end

  def encode(quality)
    @frames.each do |frame|
      quality = quality_control(quality) do
        encode_frame(frame, quality)
      end
    end
  end

  def encode_frame(frame, quality)
    quality = 100 if quality > 100
    quality = 1 if quality < 1

    skip = (frame.width / 16 * ((100 - quality).to_f / 100.0)).to_i
    skip = 1 if skip < 1
    pos = 0

    buf = ""
    while pos + skip < frame.pixelcount
      buf << frame.rpixel_at(pos) * skip # pixel_triple_at(frame, pos, @colors).pack("CCC") * skip
      pos += skip
    end
    buf << pixel_triple_at(frame, pos, @colors).pack("CCC") * (frame.pixelcount - pos)
    @io << buf
  end

  def pixel_triple_at(frame, pos, colors)
    send("#{colors}_triple_at", frame, pos)
  end

  def yuv_triple_at(frame, pos)
    r, g, b = rgb_triple_at(frame, pos)
    y = 0.299 * r + 0.587 * g + 0.114 * b
    u = -0.1687 * r - 0.3313* g + 0.5 * b + 128
    v = 0.5 * r - 0.4187 * g - 0.813 * b + 128
    [y, u, v]
  end

  def rgb_triple_at(frame, pos)
    frame.rgb_triple_at(pos, :reverse)
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
