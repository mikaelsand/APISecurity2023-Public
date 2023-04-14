using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;


namespace Permobil.TrafficInfo
{
    public static class GetTrafficInfo
    {
        [FunctionName("GetTrafficInfo")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "Get-TrainAnnouncement/{stationSignature}")] HttpRequest req, 
            string stationSignature,
            ILogger log)
        {
            try
            {
                TrafikverketService trafikverketService = new TrafikverketService(log);
                var stationsInfo = await trafikverketService.GetTrafficInfo(stationSignature);
                return new OkObjectResult(stationsInfo);
            }
            catch (Exception ex)
            {
                return new BadRequestObjectResult(ex.Message);
            }

            
        }
    }
}
