using DevOps_App.Ports;
using Microsoft.AspNetCore.Mvc;

namespace DevOps_App.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
    };

        private readonly ILogger<WeatherForecastController> _logger;
        private readonly IWeatherForecastConfigService _weatherForecastConfigService;
        public WeatherForecastController(ILogger<WeatherForecastController> logger, IWeatherForecastConfigService weatherForecastConfigService)
        {
            _logger = logger;
            _weatherForecastConfigService = weatherForecastConfigService;
        }

        [HttpGet(Name = "GetWeatherForecast")]
        public ActionResult<IEnumerable<WeatherForecast>> Get()
        {
            var numberOfDays = _weatherForecastConfigService.NumberOfDays();
            if (numberOfDays <= 0)
            {
                return BadRequest();
            }

            var forecast = Enumerable.Range(1, numberOfDays)
                .Select(index => new WeatherForecast
                {
                    Date = DateTime.Now.AddDays(index),
                    TemperatureC = Random.Shared.Next(-20, 55),
                    Summary = Summaries[Random.Shared.Next(Summaries.Length)]
                })
                .ToArray();
            return Ok(forecast);
            //return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            //{
            //    Date = DateTime.Now.AddDays(index),
            //    TemperatureC = Random.Shared.Next(-20, 55),
            //    Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            //})
            //.ToArray();
        }
    }
}