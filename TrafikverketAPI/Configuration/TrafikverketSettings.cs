using System;
using System.Collections.Generic;
using System.Text;

namespace Permobil.TrafficInfo
{
    public class TrafikverketSettings
    {
        public string APIKey { get; set; }

        public string APIBaseAddress { get; set; }

        public TrafikverketSettings()
        {
            // APIBaseAddress = "https://api.trafikinfo.trafikverket.se";
            // APIKey = "efccf6c456ca40ee809508b5af51d0f3";
            APIBaseAddress = GetEnvironmentVariable("APIBaseAddress");
            APIKey = GetEnvironmentVariable("APIKey");
        }

        private static string GetEnvironmentVariable(string name)
        {
            return System.Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }
    }
}
