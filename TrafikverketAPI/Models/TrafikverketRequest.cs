using System.Collections.Generic;
using System.Xml.Serialization;

namespace Permobil.TrafficInfo
{
    [XmlRoot(ElementName = "LOGIN")]
    public class LOGIN
    {

        [XmlAttribute(AttributeName = "authenticationkey")]
        public string Authenticationkey { get; set; }
    }

    [XmlRoot(ElementName = "EQ")]
    public class EQ
    {

        [XmlAttribute(AttributeName = "name")]
        public string Name { get; set; }

        [XmlAttribute(AttributeName = "value")]
        public string Value { get; set; }
    }

    [XmlRoot(ElementName = "GT")]
    public class GT
    {

        [XmlAttribute(AttributeName = "name")]
        public string Name { get; set; }

        [XmlAttribute(AttributeName = "value")]
        public string Value { get; set; }
    }

    [XmlRoot(ElementName = "LT")]
    public class LT
    {

        [XmlAttribute(AttributeName = "name")]
        public string Name { get; set; }

        [XmlAttribute(AttributeName = "value")]
        public string Value { get; set; }
    }

    [XmlRoot(ElementName = "AND")]
    public class AND
    {

        [XmlElement(ElementName = "GT")]
        public GT GT { get; set; }

        [XmlElement(ElementName = "LT")]
        public LT LT { get; set; }

        [XmlElement(ElementName = "EQ")]
        public List<EQ> EQ { get; set; }

        [XmlElement(ElementName = "OR")]
        public OR OR { get; set; }
    }

    [XmlRoot(ElementName = "OR")]
    public class OR
    {

        [XmlElement(ElementName = "AND")]
        public List<AND> AND { get; set; }
    }

    [XmlRoot(ElementName = "FILTER")]
    public class FILTER
    {

        [XmlElement(ElementName = "AND")]
        public AND AND { get; set; }
    }

    [XmlRoot(ElementName = "QUERY")]
    public class QUERY
    {

        [XmlElement(ElementName = "FILTER")]
        public FILTER FILTER { get; set; }

        [XmlElement(ElementName = "INCLUDE")]
        public List<string> INCLUDE { get; set; }

        [XmlAttribute(AttributeName = "objecttype")]
        public string Objecttype { get; set; }

        [XmlAttribute(AttributeName = "schemaversion")]
        public string Schemaversion { get; set; }

        [XmlAttribute(AttributeName = "orderby")]
        public string Orderby { get; set; }

        [XmlText]
        public string Text { get; set; }
    }

    [XmlRoot(ElementName = "REQUEST")]
    public class REQUEST
    {

        [XmlElement(ElementName = "LOGIN")]
        public LOGIN LOGIN { get; set; }

        [XmlElement(ElementName = "QUERY")]
        public QUERY QUERY { get; set; }

    }


}