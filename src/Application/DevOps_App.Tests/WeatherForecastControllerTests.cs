using FluentAssertions;
using DevOps_App.Ports;
using DevOps_App.Tests.Fixtures;
using DevOps_App.Tests.Utils;
using Microsoft.Extensions.DependencyInjection;
using System.Net;

namespace DevOps_App.Tests
{
    public class WeatherForecastControllerTests : IntegrationTest
    {
        public WeatherForecastControllerTests(ApiWebApplicationFactory fixture)
            : base(fixture) { }

        [Fact]
        public async Task GET_retrieves_weather_forecast()
        {
            var forecast = await _client.GetAndDeserialize<WeatherForecast[]>("/weatherforecast");
            forecast.Should().HaveCount(7);
        }

        [Fact]
        public async Task GET_with_invalid_config_results_in_a_bad_request()
        {
            var clientWithInvalidConfig = _factory.WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    services.AddTransient<IWeatherForecastConfigService, InvalidWeatherForecastConfigStub>();
                });
            })
            .CreateClient();

            var response = await clientWithInvalidConfig.GetAsync("/weatherforecast");
            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        public class InvalidWeatherForecastConfigStub : IWeatherForecastConfigService
        {
            public int NumberOfDays() => -3;
        }
    }
}
