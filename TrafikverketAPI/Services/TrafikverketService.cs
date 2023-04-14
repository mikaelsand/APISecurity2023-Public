using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Threading.Tasks;
using System.IO;

namespace Permobil.TrafficInfo
{
    public class TrafikverketService
    {
        private readonly TrafikverketSettings _settings;
        private readonly TrafikverketClient _client;

        private readonly ILogger _log;

        public TrafikverketService(ILogger log)
        {
            _settings = new TrafikverketSettings();
            _log = log;
            _client = new TrafikverketClient(new HttpClient(), _log);

        }

        public async Task<RESPONSE> GetTrafficInfo(string locationSignature)
        {
            try
            {
                var url = $"{_settings.APIBaseAddress}/v2/data.json";
                string requestBody = GetRequestXml(locationSignature, _settings.APIKey);

                HttpRequestMessage req = new HttpRequestMessage(HttpMethod.Post, url );
                req.Content = new StringContent(requestBody, System.Text.Encoding.UTF8, "application/xml");
                var response = await _client.SendAsync(req);
                
                // if bad result parse for error
                if (!response.IsSuccessStatusCode)
                {
                    throw new System.Exception(response.StatusCode.ToString());
                }

                var q = await response.Content.ReadAsAsync<Root>();
                return q.RESPONSE;

            }
            catch (System.Exception ex)
            {

                string g = ex.Message;
                _log.LogError(ex, ex.Message);
                return null;
            }
        }

        public static string DecodeString(string encodedString)
        {
            return encodedString.Replace('\"', '"');
        }

        private static string GetRequestXml(string locationSignature, string apiKey)
        {
            REQUEST requestBody = new REQUEST(){
                LOGIN = new LOGIN(){
                    Authenticationkey = apiKey
                },
                QUERY = new QUERY(){
                    Objecttype = "TrainAnnouncement",
                    Schemaversion = "1.3",
                    Orderby = "AdvertisedTimeAtLocation",
                    INCLUDE = new System.Collections.Generic.List<string>(),
                    FILTER = new FILTER(){
                        AND = new AND(){
                            EQ = new System.Collections.Generic.List<EQ>(),
                            OR = new OR(){
                                AND = new System.Collections.Generic.List<AND>()
                            }
                        }
                    }
                }
            };
            
            EQ activityType = new EQ()
            {
                Name = "ActivityType",
                Value = "Avgang"
            };


            EQ locationSign = new EQ()
            {
                Name = "LocationSignature",
                Value = locationSignature
            };

            requestBody.QUERY.FILTER.AND.EQ.Add(activityType);
            requestBody.QUERY.FILTER.AND.EQ.Add(locationSign);

            AND filter1 = new AND()
            {
                GT = new GT()
                {
                    Name = "AdvertisedTimeAtLocation",
                    Value = "$dateadd(-00:15:00)"
                },
                LT = new LT()
                {
                    Name = "AdvertisedTimeAtLocation",
                    Value = "$dateadd(02:00:00)"
                }
            };

            AND filter2 = new AND()
            {
                GT = new GT()
                {
                    Name = "AdvertisedTimeAtLocation",
                    Value = "$dateadd(00:30:00)"
                },
                LT = new LT()
                {
                    Name = "EstimatedTimeAtLocation",
                    Value = "$dateadd(-00:15:00)"
                }
            };

            requestBody.QUERY.FILTER.AND.OR.AND.Add(filter1);
            requestBody.QUERY.FILTER.AND.OR.AND.Add(filter2);

            requestBody.QUERY.INCLUDE.Add("AdvertisedTrainIdent");
            requestBody.QUERY.INCLUDE.Add("AdvertisedTimeAtLocation");
            requestBody.QUERY.INCLUDE.Add("TrackAtLocation");
            requestBody.QUERY.INCLUDE.Add("ToLocation");

            System.Xml.Serialization.XmlSerializer x = new System.Xml.Serialization.XmlSerializer(typeof(REQUEST));
            MemoryStream ms = new MemoryStream();
            x.Serialize(ms, requestBody);
            ms.Position = 0;
            StreamReader sr = new StreamReader(ms);
            return sr.ReadToEnd();            
        }
    }
}