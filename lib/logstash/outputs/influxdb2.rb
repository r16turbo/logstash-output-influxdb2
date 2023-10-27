# encoding: utf-8
require "logstash/outputs/base"

# An influxdb2 output that does nothing.
class LogStash::Outputs::InfluxDB2 < LogStash::Outputs::Base
  config_name "influxdb2"

  public
  def register
  end # def register

  public
  def receive(event)
    return "Event received"
  end # def event
end # class LogStash::Outputs::InfluxDB2
