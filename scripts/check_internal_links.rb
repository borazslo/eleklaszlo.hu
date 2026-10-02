#!/usr/bin/env ruby
# Belső linkek ellenőrzése a lefordított oldalon (_site).
# Használat: ruby scripts/check_internal_links.rb [--build]
#   --build  előtte lefordítja az oldalt (bundle exec jekyll build)
# A célt úgy keresi, ahogy az nginx: fájlként, vagy mappaként index.html-lel.
# Képfájlokra mutató linkeket nem néz (azokat a check_images.rb ellenőrzi).

require_relative 'lib/image_refs'
require_relative 'lib/link_refs'

SITE = File.join(ImageRefs::ROOT, '_site')

if ARGV.include?('--build')
  Dir.chdir(ImageRefs::ROOT) { system('bundle exec jekyll build') || abort('A Jekyll build nem sikerült.') }
end
unless File.directory?(SITE)
  warn 'Nincs lefordított oldal (_site). Futtasd így: ruby scripts/check_internal_links.rb --build'
  warn 'vagy indítsd el a fejlesztő szervert: docker compose up'
  exit 2
end

# Visszatér: [:ok] | [:missing] | [:case, létező_útvonal]
def check(parts)
  status, fs, existing = ImageRefs.resolve(SITE, parts)
  return [:missing] if status == :missing
  if File.directory?(fs)
    return [:missing] unless File.file?(File.join(fs, 'index.html'))
  elsif !File.file?(fs)
    return [:missing]
  end
  status == :case ? [:case, existing] : [:ok]
end

files = ImageRefs.files
refs = files.flat_map { |f| LinkRefs.collect(f) }
           .select { |type, _| type == :internal }
           .map(&:last)
           .reject { |r| r.target.split(/[?#]/, 2).first.to_s =~ ImageRefs::IMAGE_EXT }

problems = Hash.new { |h, k| h[k] = [] }
ok_count = 0
refs.each do |ref|
  parts = LinkRefs.internal_parts(ref.target, ref.base)
  status, existing = check(parts)
  if status == :ok
    ok_count += 1
  else
    problems[[status, '/' + parts.join('/'), existing]] << ref
  end
end

missing = problems.select { |(status, _, _), _| status == :missing }
cased = problems.select { |(status, _, _), _| status == :case }

newest_source = files.map { |f| File.mtime(File.join(ImageRefs::ROOT, f)) }.max
site_note = File.mtime(SITE) < newest_source ? '  (figyelem: a _site régebbi, mint a legújabb forrásfájl)' : ''

puts "Belső linkek ellenőrzése: #{files.size} fájl, #{refs.size} belső link#{site_note}"
puts

missing.sort_by { |(_, path, _), _| path }.each do |(_, path, _), list|
  puts "NEM LÉTEZŐ: #{path}"
  list.each { |r| puts "  #{r.file}:#{r.line}  (#{r.kind})  #{r.url}" }
end
cased.sort_by { |(_, path, _), _| path }.each do |(_, path, existing), list|
  puts "ELTÉRŐ KIS-/NAGYBETŰ: #{path}  →  létező: #{existing}"
  list.each { |r| puts "  #{r.file}:#{r.line}  (#{r.kind})  #{r.url}" }
end

summary = "#{missing.size} nem létező cél (#{missing.values.flatten.size} link), " \
          "#{cased.size} kis-/nagybetű eltérés (#{cased.values.flatten.size} link), #{ok_count} rendben."
puts unless problems.empty?
puts "Összesen: #{summary}"

if ENV['GITHUB_ACTIONS'] == 'true'
  problems.each do |(status, path, existing), list|
    title = status == :missing ? 'Nem létező belső link' : 'Eltérő kis-/nagybetű'
    msg = status == :missing ? path : "#{path} (létező: #{existing})"
    list.each do |r|
      puts "::error file=#{ImageRefs.gh_escape(r.file)},line=#{r.line},title=#{title}::#{ImageRefs.gh_escape("#{msg} — #{r.url}")}"
    end
  end

  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'a') do |out|
      out.puts '## Belső linkek'
      out.puts
      out.puts summary
      unless problems.empty?
        out.puts
        out.puts '| Probléma | Cél | Link | Hivatkozás |'
        out.puts '|---|---|---|---|'
        problems.sort_by { |(_, path, _), _| path }.each do |(status, path, existing), list|
          label = status == :missing ? 'nem létező' : "kis-/nagybetű (#{ImageRefs.md_escape(existing)})"
          list.each do |r|
            out.puts "| #{label} | `#{ImageRefs.md_escape(path)}` | #{ImageRefs.md_escape(r.url)} | #{ImageRefs.md_escape(r.file)}:#{r.line} |"
          end
        end
      end
    end
  end
end

exit(problems.empty? ? 0 : 1)
