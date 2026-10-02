#!/usr/bin/env ruby
# Permalinkek összegyűjtése a _posts és _pages fájlokból; hiba, ha valamelyik többször szerepel.
# Használat: ruby scripts/check_permalinks.rb [--list]
#   --list  az összes permalinket is kiírja

require_relative 'lib/image_refs'

Entry = Struct.new(:file, :line, :permalink, :key, :published)

def key_for(permalink)
  k = permalink.strip
  k = '/' + k unless k.start_with?('/')
  k = k.sub(%r{/+\z}, '')
  k.empty? ? '/' : k
end

files = ImageRefs.files
entries = files.filter_map do |f|
  text, body_start = ImageRefs.read(f)
  value, line = ImageRefs.front_matter_value(text, body_start, 'permalink')
  next if value.nil? || value.empty?
  published = text[0...body_start] !~ /^published:[ \t]*false[ \t]*$/
  Entry.new(f, line, value, key_for(value), published)
end

duplicates = entries.group_by(&:key).select { |_, list| list.size > 1 }.sort_by { |key, _| key }

if ARGV.include?('--list')
  entries.sort_by(&:key).each { |e| puts "#{e.permalink}\t#{e.file}#{e.published ? '' : '  (published: false)'}" }
  puts
end

puts "Permalinkek ellenőrzése: #{files.size} fájl, #{entries.size} permalink, #{files.size - entries.size} fájl permalink nélkül"
puts
duplicates.each do |key, list|
  puts "DUPLIKÁLT: #{key}/"
  list.each { |e| puts "  #{e.file}:#{e.line}  (#{e.permalink})#{e.published ? '' : '  [published: false]'}" }
end
summary = "#{duplicates.size} duplikált permalink (#{duplicates.sum { |_, l| l.size }} fájl), " \
          "#{entries.map(&:key).uniq.size} egyedi permalink."
puts unless duplicates.empty?
puts "Összesen: #{summary}"

if ENV['GITHUB_ACTIONS'] == 'true'
  duplicates.each do |key, list|
    others = ->(e) { (list - [e]).map(&:file).join(', ') }
    list.each do |e|
      msg = "#{key}/ ugyanaz, mint: #{others.call(e)}"
      puts "::error file=#{ImageRefs.gh_escape(e.file)},line=#{e.line},title=Duplikált permalink::#{ImageRefs.gh_escape(msg)}"
    end
  end

  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'a') do |out|
      out.puts '## Permalinkek'
      out.puts
      out.puts summary
      unless duplicates.empty?
        out.puts
        out.puts '| Permalink | Fájl | Megjegyzés |'
        out.puts '|---|---|---|'
        duplicates.each do |key, list|
          list.each do |e|
            out.puts "| `#{ImageRefs.md_escape(key)}/` | #{ImageRefs.md_escape(e.file)}:#{e.line} | #{e.published ? '' : 'published: false'} |"
          end
        end
      end
    end
  end
end

exit(duplicates.empty? ? 0 : 1)
