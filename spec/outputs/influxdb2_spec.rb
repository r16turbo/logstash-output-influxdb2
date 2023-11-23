# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/influxdb2"
require "influxdb-client"

describe LogStash::Outputs::InfluxDB2 do

  subject { LogStash::Outputs::InfluxDB2.new(config) }

  context "validate default config" do

    let(:config) do
    {
      "url" => "http://localhost:8086",
      "token" => "token123",
      "measurement" => "%{[kubernetes][labels][app]}",
      "fields" => "[prometheus][metrics]"
    }
    end

    before do
      subject.register
      subject.close
    end

    it "check configs" do
      options = subject.instance_variable_get(:@client).options
      expect(options[:url]).to eq "http://localhost:8086"
      expect(options[:token]).to eq "token123"

      expect(options[:bucket]).to be_nil
      expect(options[:org]).to be_nil
      expect(options[:precision]).to be_nil
      expect(options[:open_timeout]).to be_nil
      expect(options[:write_timeout]).to be_nil
      expect(options[:read_timeout]).to be_nil
      expect(options[:max_redirect_count]).to be_nil
      expect(options[:redirect_forward_authorization]).to be_nil
      expect(options[:use_ssl]).to be_nil
      expect(options[:verify_mode]).to be_nil
      expect(options[:debugging]).to be false
      expect(options[:tags]).to be_nil

      write_options = subject.instance_variable_get(:@write_api)
                             .instance_variable_get(:@write_options)
      expect(write_options.write_type).to eq 1
      expect(write_options.batch_size).to eq 1000
      expect(write_options.flush_interval).to eq 1000
      expect(write_options.retry_interval).to eq 5000
      expect(write_options.jitter_interval).to eq 0
      expect(write_options.max_retries).to eq 5
      expect(write_options.max_retry_delay).to eq 125000
      expect(write_options.max_retry_time).to eq 180000
      expect(write_options.exponential_base).to eq 2
      expect(write_options.batch_abort_on_exception).to be false

      expect(subject.instance_variable_get(:@measurement)).to eq "%{[kubernetes][labels][app]}"
      expect(subject.instance_variable_get(:@tags)).to be_nil
      expect(subject.instance_variable_get(:@fields)).to eq "[prometheus][metrics]"
      expect(subject.instance_variable_get(:@escape_value)).to be false
    end

  end

  context "validate all configs" do

    let(:config) do
    {
      "url" => "http://localhost:8086",
      "token" => "token123",
      "options" => {
        "bucket" => "test-bucket",
        "org" => "test-org",
        "precision" => "ms",
        "open_timeout" => 1001,
        "write_timeout" => 1002,
        "read_timeout" => 1003,
        "max_redirect_count" => 9999,
        "redirect_forward_authorization" => true,
        "use_ssl" => false,
        "verify_mode" => 1234,
        "debugging" => true,
        "tags" => { "foo" => "bar", "abc" => "xyz" }
      },
      "write_options" => {
        "write_type" => 2,
        "batch_size" => 100,
        "flush_interval" => 1001,
        "retry_interval" => 1002,
        "jitter_interval" => 1003,
        "max_retries" => 2001,
        "max_retry_delay" => 2002,
        "max_retry_time" => 2003,
        "exponential_base" => 9999,
        "batch_abort_on_exception" => true
      },
      "measurement" => "%{[kubernetes][labels][app]}",
      "tags" => "[prometheus][labels]",
      "fields" => "[prometheus][metrics]",
      "escape_value" => true
    }
    end

    before do
      subject.register
      subject.close
    end

    it "check configs" do
      options = subject.instance_variable_get(:@client).options
      expect(options[:url]).to eq "http://localhost:8086"
      expect(options[:token]).to eq "token123"

      expect(options[:bucket]).to eq "test-bucket"
      expect(options[:org]).to eq "test-org"
      expect(options[:precision]).to eq "ms"
      expect(options[:open_timeout]).to eq 1001
      expect(options[:write_timeout]).to eq 1002
      expect(options[:read_timeout]).to eq 1003
      expect(options[:max_redirect_count]).to eq 9999
      expect(options[:redirect_forward_authorization]).to be true
      expect(options[:use_ssl]).to be false
      expect(options[:verify_mode]).to eq 1234
      expect(options[:debugging]).to be true
      expect(options[:tags]).to eq({ "foo" => "bar", "abc" => "xyz" })

      write_options = subject.instance_variable_get(:@write_api)
                             .instance_variable_get(:@write_options)
      expect(write_options.write_type).to eq 2
      expect(write_options.batch_size).to eq 100
      expect(write_options.flush_interval).to eq 1001
      expect(write_options.retry_interval).to eq 1002
      expect(write_options.jitter_interval).to eq 1003
      expect(write_options.max_retries).to eq 2001
      expect(write_options.max_retry_delay).to eq 2002
      expect(write_options.max_retry_time).to eq 2003
      expect(write_options.exponential_base).to eq 9999
      expect(write_options.batch_abort_on_exception).to be true

      expect(subject.instance_variable_get(:@measurement)).to eq "%{[kubernetes][labels][app]}"
      expect(subject.instance_variable_get(:@tags)).to eq "[prometheus][labels]"
      expect(subject.instance_variable_get(:@fields)).to eq "[prometheus][metrics]"
      expect(subject.instance_variable_get(:@escape_value)).to be true
    end

  end

  context "validate payload - escape value" do

    let(:config) do
    {
      "url" => "http://localhost:8086",
      "token" => "token123",
      "options" => { "bucket" => "test-bucket", "org" => "test-org", "precision" => "ms" },
      "measurement" => "%{[kubernetes][labels][app]}",
      "tags" => "[prometheus][labels]",
      "fields" => "[prometheus][metrics]",
      "escape_value" => true
    }
    end

    before do
      subject.register

      write_api = subject.instance_variable_get(:@write_api)
      allow(write_api).to receive(:write_raw).and_return(nil)

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => { "count" => 123 }
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => { "count" => 123.0 }
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => { "count" => "abc" }
        }
      ))

      subject.close
    end

    it "check payload" do
      write_api = subject.instance_variable_get(:@write_api)

      expect(write_api).to have_received(:write_raw)
        .with('dummy,abc=xyz,foo=bar count=123i 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).once

      expect(write_api).to have_received(:write_raw)
        .with('dummy,abc=xyz,foo=bar count=123.0 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).once

      expect(write_api).to have_received(:write_raw)
        .with('dummy,abc=xyz,foo=bar count="abc" 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).once
    end

  end

  context "validate payload - non escape value" do

    let(:config) do
    {
      "url" => "http://localhost:8086",
      "token" => "token123",
      "options" => { "bucket" => "test-bucket", "org" => "test-org", "precision" => "ms" },
      "measurement" => "%{[kubernetes][labels][app]}",
      "tags" => "[prometheus][labels]",
      "fields" => "[prometheus][metrics]",
      "escape_value" => false
    }
    end

    before do
      subject.register

      write_api = subject.instance_variable_get(:@write_api)
      allow(write_api).to receive(:write_raw).and_return(nil)

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => { "count" => 123 }
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => { "count" => 123.0 }
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => { "count" => "abc" }
        }
      ))

      subject.close
    end

    it "check payload" do
      write_api = subject.instance_variable_get(:@write_api)

      expect(write_api).to have_received(:write_raw)
        .with('dummy,abc=xyz,foo=bar count=123 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).once

      expect(write_api).to have_received(:write_raw)
        .with('dummy,abc=xyz,foo=bar count=123.0 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).once

      expect(write_api).to have_received(:write_raw)
        .with('dummy,abc=xyz,foo=bar count=abc 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).once
    end

  end

  context "validate payload - invalid event" do

    let(:config) do
    {
      "url" => "http://localhost:8086",
      "token" => "token123",
      "options" => { "bucket" => "test-bucket", "org" => "test-org", "precision" => "ms" },
      "measurement" => "%{[kubernetes][labels][app]}",
      "tags" => "[prometheus][labels]",
      "fields" => "[prometheus][metrics]"
    }
    end

    before do
      subject.register

      write_api = subject.instance_variable_get(:@write_api)
      allow(write_api).to receive(:write_raw).and_return(nil)

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" }
          # Invalid: no metrics!
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => {}  # Invalid: no metrics!
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => { "foo" => "bar", "abc" => "xyz" },
          "metrics" => 123.0  # Invalid: metrics are not a hash!
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          # Valid: no labels!
          "metrics" => { "count" => 123.0 }
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => {},  # Valid: no labels!
          "metrics" => { "count" => 123.0 }
        }
      ))

      subject.receive(LogStash::Event.new(
        "@timestamp" => "2020-01-01T00:00:00Z",
        "kubernetes" => { "labels" => { "app" => "dummy" } },
        "prometheus" => {
          "labels" => "test",  # Invalid: labels are not a hash!
          "metrics" => { "count" => 123.0 }
        }
      ))

      subject.close
    end

    it "check payload" do
      write_api = subject.instance_variable_get(:@write_api)

      expect(write_api).to have_received(:write_raw)
        .with('dummy count=123.0 1577836800000',
              {:bucket=>"test-bucket", :org=>"test-org", :precision=>"ms"}).twice
    end

  end

end
