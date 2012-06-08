# coding: utf-8
require 'fileutils'
require 'bundler/setup'
Bundler.require(:default) if defined?(Bundler)

class Mrksm
  BLOG = 'http://blog.mariko-shinoda.net'
  LOG = './latest'

  def self.get(dir)
    mrksm = self.new(:dir => dir)
    mrksm.process
  end

  def initialize(opt = {})
    @agent = Mechanize.new
    @dir = opt[:dir] || 'image'
    @entry = latest
  end

  def process
    return unless check_updated
    begin
      dir = date.strftime('%Y%m%d')
      images.each_with_index do |img, i|
        path = "#{dir}/#{sprintf('%02d', i + 1)}#{File.extname(img)}"
        save(img, path)
      end
      @entry = previous
    end while @entry
  end

  def check_updated
    File.open(LOG, 'w'){|f| f.puts '' } unless File.exist?(LOG)
    if @entry == IO.read(LOG).chomp
      false
    else
      File.open(LOG, 'w'){|f| f.puts @entry }
      true
    end
  end

  def latest
    @page = @agent.get(BLOG)
    @page.at('a.title')['href']
  end

  def previous
    if @entry =~ /post-82\.html$/
      return 'http://blog.mariko-shinoda.net/2012/01/post-81.html'
    end
    @page ||= @agent.get(@entry)
    (elm = @page.at('a.previous')) ? elm['href'] : nil
  end

  def images
    @page = @agent.get(@entry)
    @page.at('.blogbody').search('img[width!="20"]').map do |img|
      img['src'].sub('-300x300', '').sub('-thumbnail2', '')
    end
  end

  def date
    elm = @page.at('h2.date')
    Date.strptime(elm.text, "%Y年%m月%d日") if elm
  end

  def save(image_url, path)
    file = "#{@dir}/#{path}"
    dir = File.dirname(file)

    FileUtils.mkdir_p(dir) unless Dir.exists?(dir)
    image = @agent.get(image_url)
    if image.response['content-type'] =~ /^image/
      image.save(file) unless File.exists?(file)
      puts "downloaded #{image_url} -> #{file}"
    end
  end
end

if $0 == __FILE__
  require 'optparse'
  parser = OptionParser.new
  opt = {}
  parser.banner = "Usage: #{File.basename($0)} options"
  parser.on('-d DIR','--dir DIR', 'Directory path name to save image.') {|d| opt[:dir] = d }
  parser.on('-h', '--help', 'Prints this message and quit') {
    puts parser.help
    exit 0;
  }

  begin
    parser.parse!(ARGV)
  rescue OptionParser::ParseError => e
    $stderr.puts e.message
    $stderr.puts parser.help
    exit 1
  else
    Mrksm.get(opt[:dir])
  end
end
