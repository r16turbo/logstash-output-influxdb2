# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/influxdb2"
require "logstash/codecs/plain"


describe LogStash::Outputs::InfluxDB2 do
  let(:sample_event) { LogStash::Event.new }
  let(:output) { LogStash::Outputs::InfluxDB2.new }

  before do
    output.register
  end

  describe "receive message" do
    subject { output.receive(sample_event) }

    it "returns a string" do
      expect(subject).to eq("Event received")
    end
  end
end
