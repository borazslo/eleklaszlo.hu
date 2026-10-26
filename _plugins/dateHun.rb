module Jekyll
  module DateHunFilter
    def datehun(input)
    	#https://apidock.com/ruby/DateTime/strftime
      input.strftime("%Y. %b. %-d.").gsub("Jan", "január").gsub("Feb", "február").gsub("Mar", "március").gsub("Apr", "április").gsub("Maj", "május").gsub("May", "május").gsub("Jun", "június").gsub("Jul", "július").gsub("Aug", "augusztus").gsub("Sep", "szeptember").gsub("Oct", "október").gsub("Nov", "november").gsub("Dec", "december")

    end

    # Year + month only, no day — used for pagination date-range labels and the archive page.
    def datehunmonth(input)
      input.strftime("%Y. %b").gsub("Jan", "január").gsub("Feb", "február").gsub("Mar", "március").gsub("Apr", "április").gsub("Maj", "május").gsub("May", "május").gsub("Jun", "június").gsub("Jul", "július").gsub("Aug", "augusztus").gsub("Sep", "szeptember").gsub("Oct", "október").gsub("Nov", "november").gsub("Dec", "december")
    end

    # Hungarian month name only (no year) — used for sub-headings on the archive page.
    def huhonap(input)
      input.strftime("%b").gsub("Jan", "január").gsub("Feb", "február").gsub("Mar", "március").gsub("Apr", "április").gsub("Maj", "május").gsub("May", "május").gsub("Jun", "június").gsub("Jul", "július").gsub("Aug", "augusztus").gsub("Sep", "szeptember").gsub("Oct", "október").gsub("Nov", "november").gsub("Dec", "december")
    end
  end

  class TestPlugin < Liquid::Tag
    def render(context)
      "It's Working!"
    end
  end
end

Liquid::Template.register_filter(Jekyll::DateHunFilter)
Liquid::Template.register_tag('testplugin', Jekyll::TestPlugin)
