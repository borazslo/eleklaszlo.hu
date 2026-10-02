#!/usr/bin/env ruby
# Külső képhivatkozások (image:, gallery, <img>, ![]()) összegyűjtése és elérhetőségük ellenőrzése.
# Használat: ruby scripts/check_external_images.rb [--no-check]
#   --no-check  csak listáz, nem kérdezi le az URL-eket
# Kilépési kód: 1, ha van elérhetetlen kép; a pusztán külső (de elérhető) képek csak figyelmeztetések.

require_relative 'lib/image_refs'
require_relative 'lib/http_probe'

CHECK = !ARGV.include?('--no-check')

# Visszatér: [:ok, leírás] | [:broken, ok]
def classify(result)
  return [:broken, result[1]] if result.first == :error
  _, code, type = result
  return [:broken, "HTTP #{code}"] unless (200..299).cover?(code)
  if !type.empty? && !type.start_with?('image/') && type != 'application/octet-stream'
    return [:broken, "nem kép (#{type})"]
  end
  [:ok, "HTTP #{code}#{type.empty? ? '' : ", #{type}"}"]
end

started = Time.now
files = ImageRefs.files
refs = files.flat_map { |f| ImageRefs.collect(f) }
           .reject(&:link)
           .map { |r| [r, ImageRefs.external_url(r.url)] }
           .select { |_, url| url }
by_url = Hash.new { |h, k| h[k] = [] }
refs.each { |r, url| by_url[url] << r }

results = CHECK ? HttpProbe.probe_all(by_url.keys).transform_values { |r| classify(r) } : {}

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
