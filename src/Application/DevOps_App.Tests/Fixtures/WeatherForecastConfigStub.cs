using DevOps_App.Ports;

namespace DevOps_App.Tests.Fixtures
{
    public class WeatherForecastConfigStub : IWeatherForecastConfigService
    {
        public int NumberOfDays() => 7;
    }
}
