# Közös segédek a _posts és _pages fájlok hivatkozásainak ellenőrzéséhez.

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

  # Visszatér: [teljes szöveg (LF sorvégekkel), a szövegtörzs kezdőpozíciója]
  def read(file)
    text = File.binread(File.join(ROOT, file)).force_encoding('UTF-8').scrub.gsub(/\r\n?/, "\n")
    close = text.start_with?("---\n") ? text.index(/^---[ \t]*$/, 4) : nil
    [text, close || 0]
  end

  def front_matter_value(text, body_start, key)
    m = text[0...body_start].match(/^#{Regexp.escape(key)}:[ \t]*(.*?)[ \t]*$/)
    return nil unless m
    [m[1].sub(/\A(["'])(.*)\1\z/, '\2'), line_at(text, m.begin(0))]
  end

  def collect(file)
    text, body_start = read(file)
    refs = []

    text[0...body_start].scan(/^([ \t]*(?:-[ \t]+)?)image:[ \t]*(.+?)[ \t]*$/) do
      m = Regexp.last_match
      value = m[2].sub(/\A(["'])(.*)\1\z/, '\2')
      refs << Ref.new(file, line_at(text, m.begin(0)), m[1].empty? ? 'image:' : 'gallery', value, false)
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

  # Útvonal szétbontása részekre: query/hash levágása, %XX dekódolás, . és .. feloldása.
  def split_path(path)
    p = path.split(/[?#]/, 2).first.to_s
    p = p.gsub(/%([0-9A-Fa-f]{2})/) { Regexp.last_match(1).hex.chr }
    p = p.force_encoding('UTF-8').scrub.unicode_normalize(:nfc)
    parts = []
    p.split('/').each do |part|
      next if part.empty? || part == '.'
      part == '..' ? parts.pop : parts << part
    end
    parts
  end

  # Helyi hivatkozás esetén az útvonal részei, egyébként nil.
  def local_path(url)
    u = clean(url)
    return nil if u.empty? || u.start_with?('#', '//', '{{', '{%')
    return nil if u =~ /\A[a-z][a-z0-9+.\-]*:/i
    parts = split_path(u)
    parts.empty? ? nil : parts
  end

  # Külső (http/https vagy //) hivatkozás esetén a teljes URL, egyébként nil.
  def external_url(url)
    u = clean(url)
    return 'https:' + u if u.start_with?('//')
    u =~ %r{\Ahttps?://}i ? u : nil
  end

  def children(dir)
    @children ||= {}
    return @children[dir] if @children.key?(dir)
    @children[dir] = File.directory?(dir) ? Dir.children(dir) : nil
  end

  # Útvonal keresése a fájlrendszerben, pontos kis-/nagybetűvel.
  # Visszatér: [:ok, fs_útvonal] | [:case, fs_útvonal, létező_url_útvonal] | [:missing]
  def resolve(root, parts)
    dir = root
    actual = []
    mismatch = false
    parts.each do |part|
      entries = children(dir)
      return [:missing] unless entries
      exact = entries.find { |e| e.unicode_normalize(:nfc) == part }
      found = exact || entries.find { |e| e.unicode_normalize(:nfc).casecmp?(part) }
      return [:missing] unless found
      mismatch ||= exact.nil?
      actual << found
      dir = File.join(dir, found)
    end
    mismatch ? [:case, dir, '/' + actual.join('/')] : [:ok, dir]
  end

  def gh_escape(s)
    s.to_s.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
  end

  def md_escape(s)
    s.to_s.gsub('|', '\|')
  end
end
