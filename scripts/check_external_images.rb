#!/usr/bin/env ruby
# Külső képhivatkozások (image:, gallery, <img>, ![]()) összegyűjtése és elérhetőségük ellenőrzése.
# Használat: ruby scripts/check_external_images.rb [--no-check]
#   --no-check  csak listáz, nem kérdezi le az URL-eket
# Kilépési kód: 1, ha van elérhetetlen kép; a pusztán külső (de elérhető) képek csak figyelmeztetések.

require 'net/http'
require 'uri'
require 'openssl'
require_relative 'lib/image_refs'

CHECK = !ARGV.include?('--no-check')
THREADS = 8
MAX_REDIRECTS = 5
HEADERS = {
  'User-Agent' => 'Mozilla/5.0 (compatible; eleklaszlo.hu image check)',
  'Accept' => 'image/*,*/*;q=0.8'
}.freeze

def encode(url)
  url.gsub(/[^\x21-\x7e]/) { |c| c.bytes.map { |b| format('%%%02X', b) }.join }
end

def request(uri, method)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 8
  http.read_timeout = 15
  req = method == :head ? Net::HTTP::Head.new(uri.request_uri, HEADERS) : Net::HTTP::Get.new(uri.request_uri, HEADERS.merge('Range' => 'bytes=0-1023'))
  http.start { |h| h.request(req) }
end

# Visszatér: [:ok, leírás] | [:broken, ok]
# HEAD-del kezd; ha az nem sikeres, GET-tel (Range: első 1 KB) próbálja újra.
def probe(url)
  uri = URI.parse(encode(url))
  method = :head
  MAX_REDIRECTS.times do
    res = request(uri, method)
    if res.is_a?(Net::HTTPRedirection) && res['location']
      uri = URI.join(uri.to_s, encode(res['location']))
      next
    end
    if !res.is_a?(Net::HTTPSuccess) && method == :head
      method = :get
      redo
    end
    return [:broken, "HTTP #{res.code}"] unless res.is_a?(Net::HTTPSuccess)

    type = res['content-type'].to_s.split(';').first.to_s.strip.downcase
    if !type.empty? && !type.start_with?('image/') && type != 'application/octet-stream'
      return [:broken, "nem kép (#{type})"]
    end
    return [:ok, "HTTP #{res.code}#{type.empty? ? '' : ", #{type}"}"]
  end
  [:broken, 'túl sok átirányítás']
rescue Net::OpenTimeout, Net::ReadTimeout
  [:broken, 'időtúllépés']
rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET => e
  [:broken, "kapcsolódási hiba (#{e.class.name.split('::').last})"]
rescue OpenSSL::SSL::SSLError
  [:broken, 'SSL-hiba']
rescue URI::Error, ArgumentError
  [:broken, 'érvénytelen URL']
rescue StandardError => e
  [:broken, "hiba (#{e.class})"]
end

started = Time.now
files = ImageRefs.files
refs = files.flat_map { |f| ImageRefs.collect(f) }
           .reject(&:link)
           .map { |r| [r, ImageRefs.external_url(r.url)] }
           .select { |_, url| url }
by_url = Hash.new { |h, k| h[k] = [] }
refs.each { |r, url| by_url[url] << r }

results = {}
if CHECK
  queue = Queue.new
  by_url.keys.each { |u| queue << u }
  lock = Mutex.new
  Array.new(THREADS) do
    Thread.new do
      loop do
        url = begin
          queue.pop(true)
        rescue ThreadError
          break
        end
        result = probe(url)
        lock.synchronize { results[url] = result }
      end
    end
  end.each(&:join)
end

broken = by_url.keys.select { |u| results[u]&.first == :broken }.sort
reachable = (by_url.keys - broken).sort

def print_group(title, urls, by_url, results)
  return if urls.empty?
  puts "#{title} (#{urls.size}):"
  urls.each do |url|
    note = results[url] ? "  — #{results[url].last}" : ''
    puts "  #{url}#{note}"
    by_url[url].each { |r| puts "      #{r.file}:#{r.line}  (#{r.kind})" }
  end
  puts
end

puts "Külső képhivatkozások: #{files.size} fájl, #{refs.size} hivatkozás, #{by_url.size} egyedi URL"
puts
if CHECK
  print_group('NEM ELÉRHETŐ', broken, by_url, results)
  print_group('ELÉRHETŐ, DE KÜLSŐ', reachable, by_url, results)
else
  print_group('KÜLSŐ (nem ellenőrizve)', reachable, by_url, results)
end

broken_refs = broken.sum { |u| by_url[u].size }
summary = if CHECK
            "#{broken.size} elérhetetlen URL (#{broken_refs} hivatkozás), " \
              "#{reachable.size} elérhető, de külső URL (#{refs.size - broken_refs} hivatkozás). " \
              "Idő: #{(Time.now - started).round}s."
          else
            "#{by_url.size} külső URL (#{refs.size} hivatkozás), elérhetőség nem ellenőrizve."
          end
puts "Összesen: #{summary}"

if ENV['GITHUB_ACTIONS'] == 'true'
  by_url.each do |url, list|
    bad = broken.include?(url)
    level = bad ? 'error' : 'warning'
    title = bad ? 'Elérhetetlen külső kép' : 'Külső kép'
    msg = bad ? "#{url} — #{results[url].last}" : url
    list.each do |r|
      puts "::#{level} file=#{ImageRefs.gh_escape(r.file)},line=#{r.line},title=#{title}::#{ImageRefs.gh_escape(msg)}"
    end
  end

  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'a') do |out|
      out.puts '## Külső képhivatkozások'
      out.puts
      out.puts summary
      [['❌ Nem elérhető', broken], ['⚠️ Elérhető, de külső', reachable]].each do |title, urls|
        next if urls.empty?
        out.puts
        out.puts "### #{title}"
        out.puts
        out.puts '| URL | Állapot | Hivatkozás | Mező |'
        out.puts '|---|---|---|---|'
        urls.each do |url|
          state = results[url] ? results[url].last : '–'
          by_url[url].each do |r|
            out.puts "| #{ImageRefs.md_escape(url)} | #{ImageRefs.md_escape(state)} | #{ImageRefs.md_escape(r.file)}:#{r.line} | #{ImageRefs.md_escape(r.kind)} |"
          end
        end
      end
    end
  end
end

exit(broken.empty? ? 0 : 1)
