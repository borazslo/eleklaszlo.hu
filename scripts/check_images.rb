#!/usr/bin/env ruby
# Helyi képhivatkozások ellenőrzése a _posts és _pages fájlokban.
# Használat: ruby scripts/check_images.rb   (hiba esetén 1-es kóddal lép ki)

ROOT = File.expand_path('..', __dir__)
SOURCES = %w[_posts _pages].freeze
IMAGE_EXT = /\.(jpe?g|png|gif|webp|svg|bmp|tiff?|ico)\z/i

Ref = Struct.new(:file, :line, :kind, :url, :path)

BODY_PATTERNS = [
  ['<img>',    /<img\b[^>]*?\bsrc\s*=\s*(["'])(.*?)\1/im,   2, false],
  ['![]()',    /!\[[^\]]*\]\(\s*<?([^)\s>]+)/m,             1, false],
  ['<a href>', /<a\b[^>]*?\bhref\s*=\s*(["'])(.*?)\1/im,    2, true],
  ['[]()',     /(?<!!)\[[^\]]*\]\(\s*<?([^)\s>]+)/m,        1, true]
].freeze

def normalize_text(raw)
  raw.force_encoding('UTF-8').scrub.gsub(/\r\n?/, "\n")
end

def line_at(text, offset)
  text[0, offset].count("\n") + 1
end

def local_path(url)
  u = url.strip.gsub('&amp;', '&')
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

def collect_refs(file)
  text = normalize_text(File.binread(file))
  refs = []
  body_start = 0

  if text.start_with?("---\n")
    close = text.index(/^---[ \t]*$/, 4)
    if close
      text[0...close].scan(/^([ \t]*(?:-[ \t]+)?)image:[ \t]*(.+?)[ \t]*$/) do
        m = Regexp.last_match
        value = m[2].sub(/\A(["'])(.*)\1\z/, '\2')
        kind = m[1].empty? ? 'image:' : 'gallery'
        refs << Ref.new(file, line_at(text, m.begin(0)), kind, value)
      end
      body_start = close
    end
  end

  body = text[body_start..-1]
  BODY_PATTERNS.each do |kind, regex, group, images_only|
    body.scan(regex) do
      m = Regexp.last_match
      url = m[group]
      next if images_only && url.split(/[?#]/, 2).first.to_s !~ IMAGE_EXT
      refs << Ref.new(file, line_at(text, body_start + m.begin(0)), kind, url)
    end
  end

  refs.each { |r| r.path = local_path(r.url) }
  refs.select(&:path)
end

$children = {}
def children(dir)
  return $children[dir] if $children.key?(dir)
  $children[dir] = File.directory?(dir) ? Dir.children(dir) : nil
end

# Visszatér: [:ok] | [:missing] | [:case, létező_útvonal]
def check(parts)
  dir = ROOT
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
  return [:missing] unless File.file?(dir)
  mismatch ? [:case, '/' + actual.join('/')] : [:ok]
end

def gh_escape(s)
  s.to_s.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
end

def md_escape(s)
  s.to_s.gsub('|', '\|')
end

Dir.chdir(ROOT)
files = SOURCES.flat_map { |d| Dir.glob("#{d}/**/*.{md,markdown,html}") }.sort
refs = files.flat_map { |f| collect_refs(f) }

problems = Hash.new { |h, k| h[k] = [] }
ok_count = 0
refs.each do |ref|
  status, existing = check(ref.path)
  if status == :ok
    ok_count += 1
  else
    problems[[status, '/' + ref.path.join('/'), existing]] << ref
  end
end

missing = problems.select { |(status, _, _), _| status == :missing }
cased = problems.select { |(status, _, _), _| status == :case }

puts "Képhivatkozások ellenőrzése: #{files.size} fájl, #{refs.size} helyi hivatkozás"
puts

missing.sort_by { |(_, path, _), _| path }.each do |(_, path, _), list|
  puts "HIÁNYZÓ: #{path}"
  list.each { |r| puts "  #{r.file}:#{r.line}  (#{r.kind})" }
end
cased.sort_by { |(_, path, _), _| path }.each do |(_, path, existing), list|
  puts "ELTÉRŐ KIS-/NAGYBETŰ: #{path}  →  létező fájl: #{existing}"
  list.each { |r| puts "  #{r.file}:#{r.line}  (#{r.kind})" }
end

missing_refs = missing.values.flatten.size
cased_refs = cased.values.flatten.size
summary = "#{missing.size} hiányzó fájl (#{missing_refs} hivatkozás), " \
          "#{cased.size} kis-/nagybetű eltérés (#{cased_refs} hivatkozás), #{ok_count} rendben."
puts unless problems.empty?
puts "Összesen: #{summary}"

if ENV['GITHUB_ACTIONS'] == 'true'
  problems.each do |(status, path, existing), list|
    title = status == :missing ? 'Hiányzó kép' : 'Eltérő kis-/nagybetű'
    msg = status == :missing ? path : "#{path} (létező fájl: #{existing})"
    list.each do |r|
      puts "::error file=#{gh_escape(r.file)},line=#{r.line},title=#{title}::#{gh_escape(msg)}"
    end
  end

  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'a') do |out|
      out.puts '## Képhivatkozások ellenőrzése'
      out.puts
      out.puts summary
      unless problems.empty?
        out.puts
        out.puts '| Probléma | Kép | Hivatkozás | Mező |'
        out.puts '|---|---|---|---|'
        problems.sort_by { |(_, path, _), _| path }.each do |(status, path, existing), list|
          label = status == :missing ? 'hiányzó' : "kis-/nagybetű (#{md_escape(existing)})"
          list.each do |r|
            out.puts "| #{label} | `#{md_escape(path)}` | #{md_escape(r.file)}:#{r.line} | #{md_escape(r.kind)} |"
          end
        end
      end
    end
  end
end

exit(problems.empty? ? 0 : 1)
