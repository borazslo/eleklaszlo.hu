# Képhivatkozások összegyűjtése a _posts és _pages fájlokból.

module ImageRefs
  ROOT = File.expand_path('../..', __dir__)
  SOURCES = %w[_posts _pages].freeze
  IMAGE_EXT = /\.(jpe?g|png|gif|webp|svg|bmp|tiff?|ico)\z/i

  Ref = Struct.new(:file, :line, :kind, :url, :link)

  # [mező neve, regex, URL-csoport, csak képfájlra mutató link?]
  BODY_PATTERNS = [
    ['<img>',    /<img\b[^>]*?\bsrc\s*=\s*(["'])(.*?)\1/im,   2, false],
    ['![]()',    /!\[[^\]]*\]\(\s*<?([^)\s>]+)/m,             1, false],
    ['<a href>', /<a\b[^>]*?\bhref\s*=\s*(["'])(.*?)\1/im,    2, true],
    ['[]()',     /(?<!!)\[[^\]]*\]\(\s*<?([^)\s>]+)/m,        1, true]
  ].freeze

  module_function

  def files
    Dir.chdir(ROOT) do
      SOURCES.flat_map { |d| Dir.glob("#{d}/**/*.{md,markdown,html}") }.sort
    end
  end

  def collect(file)
    text = File.binread(File.join(ROOT, file)).force_encoding('UTF-8').scrub.gsub(/\r\n?/, "\n")
    refs = []
    body_start = 0

    if text.start_with?("---\n")
      close = text.index(/^---[ \t]*$/, 4)
      if close
        text[0...close].scan(/^([ \t]*(?:-[ \t]+)?)image:[ \t]*(.+?)[ \t]*$/) do
          m = Regexp.last_match
          value = m[2].sub(/\A(["'])(.*)\1\z/, '\2')
          refs << Ref.new(file, line_at(text, m.begin(0)), m[1].empty? ? 'image:' : 'gallery', value, false)
        end
        body_start = close
      end
    end

    body = text[body_start..-1]
    BODY_PATTERNS.each do |kind, regex, group, link|
      body.scan(regex) do
        m = Regexp.last_match
        url = m[group]
        next if link && url.split(/[?#]/, 2).first.to_s !~ IMAGE_EXT
        refs << Ref.new(file, line_at(text, body_start + m.begin(0)), kind, url, link)
      end
    end
    refs
  end

  def line_at(text, offset)
    text[0, offset].count("\n") + 1
  end

  def clean(url)
    url.to_s.strip.gsub('&amp;', '&')
  end

  # Helyi hivatkozás esetén az útvonal részei, egyébként nil.
  def local_path(url)
    u = clean(url)
    return nil if u.empty? || u.start_with?('#', '//', '{{', '{%')
    return nil if u =~ /\A[a-z][a-z0-9+.\-]*:/i

    u = u.split(/[?#]/, 2).first.to_s
    u = u.gsub(/%([0-9A-Fa-f]{2})/) { Regexp.last_match(1).hex.chr }
    u = u.force_encoding('UTF-8').scrub.unicode_normalize(:nfc)
    parts = []
    u.split('/').each do |part|
      next if part.empty? || part == '.'
      part == '..' ? parts.pop : parts << part
    end
    parts.empty? ? nil : parts
  end

  # Külső (http/https vagy //) hivatkozás esetén a teljes URL, egyébként nil.
  def external_url(url)
    u = clean(url)
    return 'https:' + u if u.start_with?('//')
    u =~ %r{\Ahttps?://}i ? u : nil
  end

  def gh_escape(s)
    s.to_s.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
  end

  def md_escape(s)
    s.to_s.gsub('|', '\|')
  end
end
