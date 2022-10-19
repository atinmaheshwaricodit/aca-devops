using DevOps_App.Ports;

namespace DevOps_App.Adapters
{
    public class WeatherForecastConfigService : IWeatherForecastConfigService
    {
        public int NumberOfDays() => 7;
    }
}
