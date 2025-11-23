# Weather Forecast App

Rails app for TekSystems Ruby Coding Assessment.

## Requirements

- Accepts an address/ZIP as input
- Retrieves current weather conditions
- Caches forecast for 30 minutes
- Displays an indicator if result was served from cache

## Tech

- Ruby on Rails
- Faraday for HTTP calls
- Rails.cache for caching
- RSpec for tests
- Dotenv for environment variables
- OpenWeatherMap API for Weather data

## Setup

```bash
git clone <repo-url>
cd weather_forecast_app
bundle install
cp .env.example .env  
```

### Get your api_key
- Login to https://home.openweathermap.org/api_keys and get the api_key
- replace it in .env file

```bash
rails server
```

## Implemented Cases
- Get weather forecast for both location and zipcode
- Handled Edge cases of wrong input, no input
- Cached the data for 30 minutes
