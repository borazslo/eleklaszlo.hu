# Külső URL-ek párhuzamos lekérdezése (HEAD, szükség esetén GET), átirányításokat követve.

require 'net/http'
require 'uri'
require 'openssl'

module HttpProbe
  MAX_REDIRECTS = 5
  HEADERS = {
    'User-Agent' => 'Mozilla/5.0 (compatible; eleklaszlo.hu link check)',
    'Accept' => '*/*'
  }.freeze

  module_function

  def encode(url)
    url.gsub(/[^\x21-\x7e]/) { |c| c.bytes.map { |b| format('%%%02X', b) }.join }
  end

  def request(uri, method)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 8
    http.read_timeout = 15
    req = if method == :head
            Net::HTTP::Head.new(uri.request_uri, HEADERS)
          else
            Net::HTTP::Get.new(uri.request_uri, HEADERS.merge('Range' => 'bytes=0-1023'))
          end
    http.start { |h| h.request(req) }
  end

  # Visszatér: [:http, státuszkód, content-type] | [:error, ok]
  def probe(url, retries: 1)
    uri = URI.parse(encode(url))
    method = :head
    redirects = 0
    loop do
      res = request(uri, method)
      if res.is_a?(Net::HTTPRedirection) && res['location']
        redirects += 1
        return [:error, 'túl sok átirányítás'] if redirects > MAX_REDIRECTS
        uri = URI.join(uri.to_s, encode(res['location']))
        next
      end
      if !res.is_a?(Net::HTTPSuccess) && method == :head
        method = :get
        next
      end
      return [:http, res.code.to_i, res['content-type'].to_s.split(';').first.to_s.strip.downcase]
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    retries.positive? ? probe(url, retries: retries - 1) : [:error, 'időtúllépés']
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET, Errno::ENETUNREACH => e
    [:error, "kapcsolódási hiba (#{e.class.name.split('::').last})"]
  rescue OpenSSL::SSL::SSLError
    [:error, 'SSL-hiba']
  rescue URI::Error, ArgumentError
    [:error, 'érvénytelen URL']
  rescue StandardError => e
    [:error, "hiba (#{e.class})"]
  end

  def probe_all(urls, threads: 8)
    queue = Queue.new
    urls.each { |u| queue << u }
    results = {}
    lock = Mutex.new
    Array.new(threads) do
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
    results
  end
end
