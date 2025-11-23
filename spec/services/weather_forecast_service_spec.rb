require 'rails_helper'

RSpec.describe WeatherForecastService do
  let(:api_key) { "test_api_key" }

  before do
    Rails.cache.clear
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("WEATHER_FORECAST_API_KEY").and_return(api_key)
    allow(ENV).to receive(:fetch).with("WEATHER_FORECAST_API_KEY", anything).and_return("test_key")
  end

  describe "#call" do
    context "when input is blank" do
      it "returns an error" do
        service = described_class.new("")
        result = service.call

        expect(result[:error]).to eq("Please enter data to search for the weather forecast")
      end
    end

    context "when data is cached" do
      it "returns cached value with from_cache = true" do
        cached_value = { temp: 30, location: "hyderabad, IN" }
        Rails.cache.write("hyderabad", cached_value)

        service = described_class.new("Hyderabad")
        result = service.call

        expect(result[:temp]).to eq(30)
        expect(result[:from_cache]).to eq(true)
      end
    end

    context "when input is a city (non-numeric)" do
      it "fetches geocode and weather successfully" do
        geocode_response = double(success?: true, body: [{
          "lat" => 17.3850,
          "lon" => 78.4867,
          "name" => "Hyderabad",
          "country" => "IN"
        }])

        weather_response = double(success?: true, body: {
          "main" => { "temp" => 30, "feels_like" => 32, "humidity" => 40 },
          "weather" => [{ "description" => "clear sky" }]
        })

        faraday_conn = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(faraday_conn)

        expect(faraday_conn).to receive(:get).with("/geo/1.0/direct", hash_including(q: "hyderabad"))
                                             .and_return(geocode_response)

        expect(faraday_conn).to receive(:get).with("/data/2.5/weather", anything)
                                             .and_return(weather_response)

        service = described_class.new("Hyderabad")
        result  = service.call

        expect(result[:temp]).to eq(30)
        expect(result[:location]).to eq("Hyderabad, IN")
        expect(result[:from_cache]).to eq(false)
      end
    end

    context "when geocoding fails" do
      it "returns location not found" do
        faraday_conn = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(faraday_conn)

        response = double(success?: false, body: {})
        allow(faraday_conn).to receive(:get).and_return(response)

        service = described_class.new("NoWhereLand")

        result = service.call
        expect(result[:error]).to eq("Location not found")
      end
    end

    context "when API key is missing" do
      it "returns an error" do
        allow(ENV).to receive(:[]).with("WEATHER_FORECAST_API_KEY").and_return(nil)
        service = described_class.new("Hyderabad")

        result = service.call
        expect(result[:error]).to eq("API key missing")
      end
    end
  end
end
