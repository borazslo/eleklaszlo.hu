# Linkek (href-ek) összegyűjtése és osztályozása a _posts és _pages fájlokból.

require_relative 'image_refs'

module LinkRefs
  OWN_HOST = %r{\A(?:https?:)?//(?:www\.)?eleklaszlo\.hu(?=[/?#:]|\z)}i

  Ref = Struct.new(:file, :line, :kind, :url, :target, :base)

  PATTERNS = [
    ['<a href>', /<a\b[^>]*?\bhref\s*=\s*(["'])(.*?)\1/im, 2],
    ['[]()',     /(?<!!)\[[^\]]*\]\(\s*<?([^)\s>]+)/m,     1],
    ['[ref]:',   /^[ \t]{0,3}\[[^\]]+\]:[ \t]*<?([^\s>]+)/, 1],
    ['<url>',    %r{<(https?://[^>\s]+)>}i,                1]
  ].freeze

  module_function

  # Visszatér: [:internal, útvonal] | [:external, url] | [:skip]
  def classify(url)
    u = ImageRefs.clean(url)
    return [:skip] if u.empty? || u.start_with?('#', '{{', '{%')
    if u =~ OWN_HOST
      rest = u.sub(OWN_HOST, '').sub(/\A:\d+/, '')
      return [:internal, rest.empty? ? '/' : rest]
    end
    return [:external, 'https:' + u] if u.start_with?('//')
    return [:external, u] if u =~ %r{\Ahttps?://}i
    return [:skip] if u =~ /\A[a-z][a-z0-9+.\-]*:/i
    [:internal, u]
  end

  # Az összes link a fájlból; a target az osztályozott cél, a base a fájl permalinkje.
  def collect(file)
    text, body_start = ImageRefs.read(file)
    base, = ImageRefs.front_matter_value(text, body_start, 'permalink')
    body = text[body_start..-1]
    refs = []
    PATTERNS.each do |kind, regex, group|
      body.scan(regex) do
        m = Regexp.last_match
        type, target = classify(m[group])
        next if type == :skip
        refs << [type, Ref.new(file, ImageRefs.line_at(text, body_start + m.begin(0)), kind, m[group], target, base)]
      end
    end
    refs
  end

  # Belső link útvonalrészei, a relatív linkeket a fájl permalinkjéhez képest feloldva.
  def internal_parts(target, base)
    path = target.split(/[?#]/, 2).first.to_s
    return ImageRefs.split_path(base.to_s) if path.empty?
    return ImageRefs.split_path(path) if path.start_with?('/')
    base_dir = base.to_s.end_with?('/') ? base.to_s : base.to_s.sub(%r{[^/]*\z}, '')
    ImageRefs.split_path(base_dir + path)
  end
end
