require 'mechanize'
require 'mrksm/downloader'
require 'mrksm/entry'
require 'mrksm/log'

module Mrksm
  BLOG = 'http://blog.mariko-shinoda.net'
  AGENT = Mechanize.new

  module_function
  def absolute_url path
    return path if path =~ /\Ahttp/
    "#{BLOG}/#{path.sub(%r[\A\.?/+], '')}"
  end
end
