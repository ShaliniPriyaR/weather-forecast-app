require "rails_helper"

RSpec.describe WeatherForecastsController, type: :controller do
  describe "POST #create" do
    context "when service returns an error" do
      it "renders :new with alert" do
        expect_any_instance_of(WeatherForecastService)
          .to receive(:call)
          .and_return({ error: "Location not found" })

        post :create, params: { input: "InvalidPlace" }

        expect(flash[:alert]).to eq("Location not found")
        expect(response).to render_template(:new)
        expect(response.status).to eq(422)
      end
    end

    context "when service returns success" do
      let(:result) do
        {
          location: "Hyderabad, IN",
          temp: 30,
          feels_like: 32,
          humidity: 40,
          description: "clear sky",
          from_cache: false
        }
      end

      it "renders :show with result" do
        expect_any_instance_of(WeatherForecastService)
          .to receive(:call)
          .and_return(result)

        post :create, params: { input: "Hyderabad" }

        expect(assigns(:result)).to eq(result)
        expect(response).to render_template(:show)
      end
    end
  end
end
