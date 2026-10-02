#!/usr/bin/env ruby
# Helyi képhivatkozások ellenőrzése a _posts és _pages fájlokban.
# Használat: ruby scripts/check_images.rb   (hiba esetén 1-es kóddal lép ki)

require_relative 'lib/image_refs'

$children = {}
def children(dir)
  return $children[dir] if $children.key?(dir)
  $children[dir] = File.directory?(dir) ? Dir.children(dir) : nil
end

# Visszatér: [:ok] | [:missing] | [:case, létező_útvonal]
def check(parts)
  dir = ImageRefs::ROOT
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

files = ImageRefs.files
refs = files.flat_map { |f| ImageRefs.collect(f) }
           .map { |r| [r, ImageRefs.local_path(r.url)] }
           .select { |_, path| path }

problems = Hash.new { |h, k| h[k] = [] }
ok_count = 0
refs.each do |ref, path|
  status, existing = check(path)
  if status == :ok
    ok_count += 1
  else
    problems[[status, '/' + path.join('/'), existing]] << ref
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
      puts "::error file=#{ImageRefs.gh_escape(r.file)},line=#{r.line},title=#{title}::#{ImageRefs.gh_escape(msg)}"
    end
  end

  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'a') do |out|
      out.puts '## Helyi képhivatkozások'
      out.puts
      out.puts summary
      unless problems.empty?
        out.puts
        out.puts '| Probléma | Kép | Hivatkozás | Mező |'
        out.puts '|---|---|---|---|'
        problems.sort_by { |(_, path, _), _| path }.each do |(status, path, existing), list|
          label = status == :missing ? 'hiányzó' : "kis-/nagybetű (#{ImageRefs.md_escape(existing)})"
          list.each do |r|
            out.puts "| #{label} | `#{ImageRefs.md_escape(path)}` | #{ImageRefs.md_escape(r.file)}:#{r.line} | #{ImageRefs.md_escape(r.kind)} |"
          end
        end
      end
    end
  end
end

exit(problems.empty? ? 0 : 1)
