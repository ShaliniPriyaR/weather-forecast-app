class WeatherForecastService
  BASE_URL = "https://api.openweathermap.org"

  CACHE_EXPIRY = 30.minutes

  # Initialize service with user input
  # Prepare Faraday connection
  #
  # @param input [String] location string or ZIP
  def initialize(input)
    @input = input.to_s.strip.downcase
    @api_key = ENV['WEATHER_FORECAST_API_KEY']

    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :url_encoded
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
    end
  end

  # Main entry point to fetch weather data.
  #
  # @return [Hash] weather result or error message
  def call
    return error('Please enter data to search for the weather forecast') if @input.blank?

    return error('API key missing') if @api_key.blank?

    cached = Rails.cache.read("#{@input}")
    return cached.merge(from_cache: true) if cached.present?

    coords = fetch_geocode
    return error('Location not found') unless coords

    result = fetch_weather(coords)
    return result if result[:error]

    Rails.cache.write("#{@input}", result, expires_in: CACHE_EXPIRY)
    result.merge(from_cache: false)
  end

  private

  # Return a standard error response
  def error(msg)
    { error: msg }
  end

  # Determines whether to do a ZIP or city geocode search
  #
  # @return [Hash, nil] coordinates hash (lat/lon) or nil
  def fetch_geocode
    if @input.match?(/\A\d+\z/)
      geocode_zip
    else
      geocode_city
    end
  end

  # Fetch geolocation for a city name
  #
  # @return [Hash, nil]
  def geocode_city
    response = @conn.get("/geo/1.0/direct", {
      q: @input,
      limit: 1,
      appid: @api_key
    })

    parse_geocode(response)
  end

  # Fetch geolocation for a zipcode
  #
  # @return [Hash, nil]
  def geocode_zip
    response = @conn.get("/geo/1.0/zip", {
      zip: "#{@input},IN",
      appid: @api_key
    })

    parse_geocode(response)
  end

  # Parses geocode API response
  #
  # @param response [Faraday::Response]
  #
  # @return [Hash, nil]
  def parse_geocode(response)
    return nil unless response.success? && response.body.present?

    data = response.body
    data = data.first if data.is_a?(Array)
    {
      lat: data['lat'],
      lon: data['lon'],
      name: data['name'],
      country: data['country']
    }
  end

  # Fetches final weather data using coordinates
  #
  # @param coords [Hash]
  #
  # @return [Hash]
  def fetch_weather(coords)
    response = @conn.get('/data/2.5/weather', {
      lat: coords[:lat],
      lon: coords[:lon],
      appid: @api_key,
      units: 'metric'
    })

    return error('Unable to fetch weather') unless response.success?

    data = response.body

    {
      location: "#{coords[:name]}, #{coords[:country]}",
      temp: data.dig('main', 'temp'),
      feels_like: data.dig('main', 'feels_like'),
      humidity: data.dig('main', 'humidity'),
      description: data['weather']&.first&.dig('description'),
      raw: data
    }
  end
end
