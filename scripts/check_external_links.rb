#!/usr/bin/env ruby
# Külső linkek elérhetőségének ellenőrzése.
# Használat: ruby scripts/check_external_links.rb [--no-check]
#   --no-check  csak listáz, nem kérdezi le az URL-eket
# Hiba: 404/410/5xx, DNS-, kapcsolódási, SSL-hiba, időtúllépés.
# Bizonytalan (figyelmeztetés): 401/403/429/520/999 és átirányítás-hurok – gyakran csak a robotokat
# tiltja az oldal (pl. a twitter.com 520-at ad), böngészőben működhet.

require_relative 'lib/image_refs'
require_relative 'lib/link_refs'
require_relative 'lib/http_probe'

CHECK = !ARGV.include?('--no-check')
UNCERTAIN_CODES = [401, 403, 429, 520, 999].freeze
UNCERTAIN_ERRORS = ['túl sok átirányítás'].freeze

# Visszatér: [:ok | :uncertain | :broken, leírás]
def classify(result)
  if result.first == :error
    return [UNCERTAIN_ERRORS.include?(result[1]) ? :uncertain : :broken, result[1]]
  end
  code = result[1]
  return [:ok, "HTTP #{code}"] if (200..399).cover?(code)
  return [:uncertain, "HTTP #{code}"] if UNCERTAIN_CODES.include?(code)
  [:broken, "HTTP #{code}"]
end

started = Time.now
files = ImageRefs.files
refs = files.flat_map { |f| LinkRefs.collect(f) }
           .select { |type, _| type == :external }
           .map(&:last)
by_url = Hash.new { |h, k| h[k] = [] }
refs.each { |r| by_url[r.target] << r }

results = CHECK ? HttpProbe.probe_all(by_url.keys, threads: 16).transform_values { |r| classify(r) } : {}
broken = by_url.keys.select { |u| results[u]&.first == :broken }.sort
uncertain = by_url.keys.select { |u| results[u]&.first == :uncertain }.sort
ok = by_url.keys - broken - uncertain

def print_group(title, urls, by_url, results)
  return if urls.empty?
  puts "#{title} (#{urls.size}):"
  urls.each do |url|
    puts "  #{url}  — #{results[url].last}"
    by_url[url].each { |r| puts "      #{r.file}:#{r.line}  (#{r.kind})" }
  end
  puts
end

puts "Külső linkek: #{files.size} fájl, #{refs.size} link, #{by_url.size} egyedi URL"
puts

summary = if CHECK
            print_group('NEM ELÉRHETŐ', broken, by_url, results)
            print_group('BIZONYTALAN (lehet, hogy csak a robotokat tiltja)', uncertain, by_url, results)
            "#{broken.size} elérhetetlen URL (#{broken.sum { |u| by_url[u].size }} link), " \
              "#{uncertain.size} bizonytalan, #{ok.size} rendben. Idő: #{(Time.now - started).round}s."
          else
            by_url.keys.sort.each { |u| puts "  #{u}" }
            puts
            "#{by_url.size} külső URL, elérhetőség nem ellenőrizve."
          end
puts "Összesen: #{summary}"

if ENV['GITHUB_ACTIONS'] == 'true'
  [[broken, 'error', 'Elérhetetlen külső link'], [uncertain, 'warning', 'Bizonytalan külső link']].each do |urls, level, title|
    urls.each do |url|
      by_url[url].each do |r|
        puts "::#{level} file=#{ImageRefs.gh_escape(r.file)},line=#{r.line},title=#{title}::#{ImageRefs.gh_escape("#{url} — #{results[url].last}")}"
      end
    end
  end

  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'a') do |out|
      out.puts '## Külső linkek'
      out.puts
      out.puts summary
      [['❌ Nem elérhető', broken], ['⚠️ Bizonytalan', uncertain]].each do |title, urls|
        next if urls.empty?
        out.puts
        out.puts "### #{title}"
        out.puts
        out.puts '| URL | Állapot | Hivatkozás |'
        out.puts '|---|---|---|'
        urls.each do |url|
          by_url[url].each do |r|
            out.puts "| #{ImageRefs.md_escape(url)} | #{ImageRefs.md_escape(results[url].last)} | #{ImageRefs.md_escape(r.file)}:#{r.line} |"
          end
        end
      end
    end
  end
end

exit(broken.empty? ? 0 : 1)
