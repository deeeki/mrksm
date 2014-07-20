require 'active_support'
require 'active_support/core_ext/date'

module Mrksm
  class Entry
    FIRST_SLUG = '20111201'
    attr_reader :url

    class << self
      def latest_urls
        @urls ||= AGENT.get(BLOG).at('#latest').search('a').map do |a|
          Mrksm.absolute_url(a['href'])
        end
      end

      def latest
        new(latest_urls.first)
      end

      def monthly_first_urls from: nil, to: nil, **options
        date = Date.parse(to) rescue Date.today
        from = (from && from > FIRST_SLUG) ? from : FIRST_SLUG
        slugs = []
        begin
          slug = "#{date.strftime('%Y%m')}01"
          slugs << slug
          date = date.months_ago(1)
        end while from < slug
        slugs.map{|s| Mrksm.absolute_url("#{s}.html") }
      end
    end

    def initialize url
      @url = url
    end

    def page
      @page ||= AGENT.get(url)
    end

    def date
      @date ||= (elm = page.at('p.postDate')) ? Date.parse(elm.text) : nil
    end

    def slug
      @slug ||= "#{File.basename(@url, '.*')}"
    end

    def images
      @images ||= page.at('#entryBody').search('img[data-original]').map do |img|
        Mrksm.absolute_url(img['data-original'])
      end
    end

    def next_slug
      (slug.to_i + 1).to_s
    end

    def next_url
      "#{BLOG}/#{next_slug}.html"
    end

    def prev_slug
      slug = (slug.to_i - 1).to_s
      slug[-1] == '0' ? nil : slug
    end

    def prev_url
      "#{BLOG}/#{prev_slug}.html" if prev_slug
    end

    def not_found?
      page.title.nil?
    end
  end
end
