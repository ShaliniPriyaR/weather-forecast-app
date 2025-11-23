class WeatherForecastsController < ApplicationController
  def new
  end

  def create
    input = params[:input]

    service = WeatherForecastService.new(input)
    @result = service.call

    if @result[:error].present?
      flash.now[:alert] = @result[:error]
      render :new, status: :unprocessable_entity
    else
      render :show
    end
  end
end
