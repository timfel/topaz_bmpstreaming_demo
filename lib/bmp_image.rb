class BMPImage
  attr_accessor :width, :height, :data, :rdata, :header

  def initialize(path)
    @header = ""
    File.open(path, "rb") do |f|
      identify_format(f)
      offset = read_bitmap_offset(f)
      @width, @height = read_dimensions(f)
      skip_to_data(f, offset)
      @data = f.read
      @rdata = @data.reverse
    end
    $stderr.puts "Loaded #{path} with #{@width}x#{@height} px*px"
  rescue Exception => e
    raise "Error (#{e}): #{path} does not appear to be a supported BMP file"
  end

  def identify_format(f)
    ident = header_read(f, 2)
    raise "Error: #{path} is not a BMP file" if ident != "BM"
  end

  def read_bitmap_offset(f)
    size = header_read(f, 4).unpack("l")[0]
    reserved = header_read(f, 4)
    offset = header_read(f, 4).unpack("l")[0]
    raise "Error: No DIB header" if offset < 14 + 12 # BMPHEADER + DIBCOREHEADER
    return offset
  end

  def read_dimensions(f)
    dibheadersize = header_read(f, 4).unpack("L")[0]
    raise "Error: Broken DIB header" if dibheadersize < 12

    @width = header_read(f, 4).unpack("l")[0]
    @height = header_read(f, 4).unpack("l")[0]

    if dibheadersize >= 14
      colorplanes = header_read(f, 2).unpack("S")
      if dibheadersize >= 16
        bpp = header_read(f, 2).unpack("S")[0]
        raise "We only support 24bit images" if bpp != 24
      end
    end
    return @width, @height
  end

  def skip_to_data(f, offset)
    header_read(f, offset - @header.size)
  end

  def header_read(file, bits)
    res = file.read(bits)
    @header << res
    res
  end
  private :header_read

  def pixel_at(pos)
    @data[pos * 3, 3]
  end

  def rpixel_at(pos)
    @rdata[pos * 3, 3]
  end

  def rgb_triple_at(pos, direction=:forward)
    rgb = direction == :reverse ? rpixel_at(pos) : pixel_at(pos)
    r,g,b = rgb[0].unpack("C"), rgb[1].unpack("C"), rgb[2].unpack("C")
    return [r, g, b].map { |ary| ary[0] }
  end

  def pixelcount
    @data.size / 3
  end

  def write(quality, path)
    quality = 100 if quality > 100
    quality = 1 if quality < 1

    skip = (width / 8 * ((100 - quality).to_f / 100.0)).to_i
    skip = 1 if skip < 1
    pos = 0
    File.open(path) do |io|
      io << header

      while pos < pixelcount
        io << pixel_at(pos) * skip
        pos += skip
      end
    end
  end
end

if defined? Topaz
  class String
    def unpack(ignored)
      # Just works for those well-formed things below
      bytes = []
      (0...size).each do |idx|
        bytes << getbyte(idx)
      end
      num = 0
      bytes.each_with_index do |ea, idx|
        num += (ea << (idx * 8))
      end
      [num]
    end
  end
end
