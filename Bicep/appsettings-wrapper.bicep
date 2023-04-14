param currentAppSettings object 
param appSettings object
param functionName string

resource siteconfig 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${functionName}/appsettings'
  properties: union(currentAppSettings, appSettings)
}
