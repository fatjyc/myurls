# encoding: UTF-8

require 'ipaddr'
require 'socket'

module Myurls
  module XipDns
    TYPE_A = 1
    TYPE_NS = 2
    TYPE_SOA = 6
    CLASS_IN = 1

    module_function

    def extract_ipv4(name, zone)
      labels = relative_labels(name, zone)
      return if labels.nil? || labels.empty?

      candidates = []
      candidates << labels.last.tr('-', '.') if labels.last.match?(/\A\d+(?:-\d+){3}\z/)
      candidates << labels.last(4).join('.') if labels.length >= 4

      candidates.find { |candidate| valid_ipv4?(candidate) }
    end

    def answer(packet, zone:, default_ip:, nameserver:, ttl: 300)
      return if packet.bytesize < 12

      id, flags, question_count = packet.unpack('n3')
      return if question_count.zero?

      name, offset = decode_name(packet, 12)
      return if offset + 4 > packet.bytesize

      question_type, question_class = packet.byteslice(offset, 4).unpack('n2')
      question = packet.byteslice(12, offset + 4 - 12)
      records = records_for(
        name,
        question_type,
        question_class,
        zone: zone,
        default_ip: default_ip,
        nameserver: nameserver,
        ttl: ttl
      )

      response_flags = 0x8400 | (flags & 0x0100)
      [id, response_flags, 1, records.length, 0, 0].pack('n6') + question + records.join
    rescue ArgumentError, IPAddr::InvalidAddressError
      nil
    end

    def run(host: '0.0.0.0', port: 8053, zone:, default_ip:, nameserver:, ttl: 300)
      udp = UDPSocket.new
      udp.bind(host, port)
      tcp = TCPServer.new(host, port)

      udp_thread = Thread.new do
        loop do
          packet, sender = udp.recvfrom(4096)
          response = answer(packet, zone: zone, default_ip: default_ip, nameserver: nameserver, ttl: ttl)
          udp.send(response, 0, sender[3], sender[1]) if response
        end
      end

      tcp_thread = Thread.new do
        loop do
          client = tcp.accept
          Thread.new(client) do |connection|
            length_data = connection.read(2)
            next unless length_data&.bytesize == 2

            packet = connection.read(length_data.unpack1('n'))
            response = answer(packet, zone: zone, default_ip: default_ip, nameserver: nameserver, ttl: ttl)
            connection.write([response.bytesize].pack('n') + response) if response
          ensure
            connection.close
          end
        end
      end

      warn "xip DNS listening on #{host}:#{port} for #{normalize_name(zone)}"
      [udp_thread, tcp_thread].each(&:join)
    ensure
      udp&.close
      tcp&.close
    end

    def records_for(name, type, klass, zone:, default_ip:, nameserver:, ttl:)
      return [] unless klass == CLASS_IN

      normalized_name = normalize_name(name)
      normalized_zone = normalize_name(zone)
      return [] unless normalized_name == normalized_zone || normalized_name.end_with?(".#{normalized_zone}")

      case type
      when TYPE_A
        ip = normalized_name == normalized_zone ? default_ip : extract_ipv4(normalized_name, normalized_zone)
        ip ? [resource_record(TYPE_A, ttl, IPAddr.new(ip).hton)] : []
      when TYPE_NS
        normalized_name == normalized_zone ? [resource_record(TYPE_NS, ttl, encode_name(nameserver))] : []
      when TYPE_SOA
        return [] unless normalized_name == normalized_zone

        soa = encode_name(nameserver) + encode_name("hostmaster.#{normalized_zone}")
        soa += [Time.now.to_i, 3600, 600, 86_400, ttl].pack('N5')
        [resource_record(TYPE_SOA, ttl, soa)]
      else
        []
      end
    end

    def resource_record(type, ttl, data)
      [0xc00c, type, CLASS_IN, ttl, data.bytesize].pack('nnnNn') + data
    end

    def relative_labels(name, zone)
      normalized_name = normalize_name(name)
      normalized_zone = normalize_name(zone)
      return [] if normalized_name == normalized_zone
      return unless normalized_name.end_with?(".#{normalized_zone}")

      normalized_name.delete_suffix(".#{normalized_zone}").split('.')
    end

    def valid_ipv4?(candidate)
      IPAddr.new(candidate).ipv4? && candidate.split('.').length == 4
    rescue IPAddr::InvalidAddressError
      false
    end

    def normalize_name(name)
      name.to_s.downcase.sub(/\.\z/, '')
    end

    def decode_name(packet, offset)
      labels = []

      loop do
        length = packet.getbyte(offset)
        raise ArgumentError, 'invalid DNS name' if length.nil?

        offset += 1
        break if length.zero?
        raise ArgumentError, 'compressed question names are unsupported' unless (length & 0xc0).zero?

        label = packet.byteslice(offset, length)
        raise ArgumentError, 'truncated DNS name' unless label&.bytesize == length

        labels << label
        offset += length
      end

      [labels.join('.'), offset]
    end

    def encode_name(name)
      normalize_name(name).split('.').map { |label| [label.bytesize].pack('C') + label }.join + "\0"
    end
  end
end
