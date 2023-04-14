using System;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;

namespace Permobil.TrafficInfo
{
    public class TrafikverketClient
    {
        private readonly HttpClient _client;
        private readonly ILogger _logger;


        public TrafikverketClient(HttpClient client, ILogger logger)
        {
            _client = client;            
            _logger = logger;
        }
        
        public async Task<T> SendAsync<T>(HttpRequestMessage req)
        {
            HttpResponseMessage response = null;
            string content = "";

            response = await _client.SendAsync(req);
            content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                var httpRequestException = new HttpRequestException("There was an error calling the service");
                _logger.LogError($"{"There was an error calling the service"} {HttpStatusCode.InternalServerError} response", httpRequestException);
                throw httpRequestException;
            }
            
            var result = JsonConvert.DeserializeObject<T>(content);
            return result;
        }

        public async Task<HttpResponseMessage> SendAsync(HttpRequestMessage req)
        {
            string content = "";

            var responseBody = await _client.SendAsync(req);
            
            if (!responseBody.IsSuccessStatusCode)
            {
                var httpRequestException = new HttpRequestException("There was an error calling the service");
                _logger.LogError($"{"There was an error calling the service"} {HttpStatusCode.InternalServerError} response", httpRequestException);
                throw httpRequestException;
            }
            
            var result = JsonConvert.DeserializeObject(content);
            return responseBody;
        }

    }
}