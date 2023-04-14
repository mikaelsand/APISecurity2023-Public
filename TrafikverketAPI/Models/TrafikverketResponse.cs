using System;
using System.Collections.Generic;

namespace Permobil.TrafficInfo
{
// Root myDeserializedClass = JsonConvert.DeserializeObject<Root>(myJsonResponse);
    public class RESPONSE
    {
        public List<RESULT> RESULT { get; set; }
    }

    public class RESULT
    {
        public List<TrainAnnouncement> TrainAnnouncement { get; set; }
    }

    public class Root
    {
        public RESPONSE RESPONSE { get; set; }
    }

    public class ToLocation
    {
        public string LocationName { get; set; }
        public int Priority { get; set; }
        public int Order { get; set; }
    }

    public class TrainAnnouncement
    {
        public DateTime AdvertisedTimeAtLocation { get; set; }
        public string AdvertisedTrainIdent { get; set; }
        public List<ToLocation> ToLocation { get; set; }
        public string TrackAtLocation { get; set; }
    }



}