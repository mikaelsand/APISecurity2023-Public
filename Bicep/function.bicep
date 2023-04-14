param TrafikVerketAPIUrl string = 'https://api.trafikinfo.trafikverket.se'
@secure()
param TrafikVerketAPIKey string

var env                   = 'TEST'
var location              = resourceGroup().location
var locationTwoLetter     = 'ne'
var systemIdentifier      = 'SYS00X'
var systemName            = 'API-security-demo'
var dotnetRuntime         = 'v6.0'

// existing
var appInsightName       = 'MyAppInsightName'
var appInsightRGName     = 'MyAppInsightNameResourceGroup'

var baseName             = '${toUpper(systemIdentifier)}-${toUpper(locationTwoLetter)}-${systemName}-${toUpper(env)}'
var functionAppName      = '${baseName}-Func'
var functionAppPlanName  = '${baseName}-Plan'
var storageAccountName   = '${toLower(systemIdentifier)}${toLower(uniqueString(systemName, resourceGroup().name, 'func'))}${toLower(env)}'

// SKU
var EnvironmentSettings = {
  PROD: {
    sku: {
      tier: 'Standard'
      name: 'S1'
      capacity: 1
    }
    alwaysOn: true
  }
  TEST: {
    sku: {
      tier: 'Dynamic'
      name: 'Y1'
      capacity: 0
    }
    alwaysOn: false
  }
}

resource azureFunction 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: azureServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: EnvironmentSettings[env].alwaysOn
      netFrameworkVersion: dotnetRuntime
    }
  }
  tags: resourceGroup().tags
}

module appSettings 'appsettings-wrapper.bicep' = {
  name: '${functionAppName}-appsettings'
  params: {
    functionName: azureFunction.name
    currentAppSettings: list('${azureFunction.id}/config/appsettings', '2020-12-01').properties
    appSettings: {
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsight.properties.InstrumentationKey
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      WEBSITE_RUN_FROM_PACKAGE: '1'
      WEBSITE_CONTENTSHARE: toLower(functionAppName)
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING:'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'      
      AzureWebJobsStorage:'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'
      APIBaseAddress: TrafikVerketAPIUrl
      APIKey: TrafikVerketAPIKey
    }
  }
}

resource azureServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: functionAppPlanName
  location: location
  kind: 'functionapp'
  sku: EnvironmentSettings[env].sku
  properties: {
    reserved: false
  }
  tags: resourceGroup().tags
}

resource functionStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
  tags: resourceGroup().tags
}

// A new application insight that will be linked to the webapp.
resource appInsight 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  scope: resourceGroup(appInsightRGName)
  name: appInsightName
}
  

