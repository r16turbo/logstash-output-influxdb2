# encoding: utf-8
require "logstash/outputs/base"
require "influxdb-client"

class LogStash::Outputs::InfluxDB2 < LogStash::Outputs::Base
  config_name "influxdb2"

  # https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/Client.html
  config :url, :validate => :string, :required => true
  config :token, :validate => :password, :required => true
  config :options, :validate => :hash, :default => {}

  # https://influxdata.github.io/influxdb-client-ruby/InfluxDB2/WriteOptions.html
  config :write_options, :validate => :hash, :default => {}

  config :measurement, :validate => :string, :required => true
  config :tags, :validate => :string
  config :fields, :validate => :string, :required => true

  config :escape_value, :validate => :boolean, :default => false

  public
  def register
    @precision = @options.fetch("precision", InfluxDB2::DEFAULT_WRITE_PRECISION)
    @client = InfluxDB2::Client.new(@url, @token.value, **_to_kwargs(@options))
    write_options = InfluxDB2::WriteOptions.new(**_to_kwargs(@write_options))
    @write_api = @client.create_write_api(write_options: write_options)
  end # def register

  public
  def receive(event)
    fields = event.get(@fields)
    return unless fields.is_a?(Hash) && ! fields.empty?

    tags = @tags.nil? ? nil : event.get(@tags)
    return unless tags.nil? || tags.is_a?(Hash)

    unless @escape_value
      fields = fields.transform_values { |v| ToStr.new(v) }
    end

    @write_api.write(data: InfluxDB2::Point.new(
      name: event.sprintf(@measurement), tags: tags, fields: fields,
      time: event.timestamp.time, precision: @precision))

  rescue InfluxDB2::InfluxError => ie
    @logger.warn("HTTP communication error while writing to InfluxDB", :exception => ie)
  rescue Exception => e
    @logger.warn("Non recoverable exception while writing to InfluxDB", :exception => e)
  end # def event

  def close
    @client.close!
  end

  def _to_kwargs(hash)
    hash.map do |k,v|
      case v
      when "true"  then v = true
      when "false" then v = false
      end
      [k.to_sym, v]
    end.to_h
  end

  # prevents auto escape by client library.
  class ToStr
    def initialize(obj)
      @obj = obj
    end

    def to_s
      @obj.to_s
    end

    def to_str
      @obj.to_str
    end
  end

end # class LogStash::Outputs::InfluxDB2
