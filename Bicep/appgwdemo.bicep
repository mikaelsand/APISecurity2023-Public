var location                  = resourceGroup().location
var env                       = 'TEST'

var ApimInstanceName          = 'MyAPImInstance'
var ApimInstanceResourceGroup = 'MyAPImInstanceResourceGroup'

var publicIpName              = 'SYS00X-API-security-demo-pip'
var appGwNetworkName          = 'azne-sys00x-vnet'
var appGwName                 = 'SYS00X-azne-API-security-demo-agw'
var defaultFirewallPolicyName = 'SYS00X-azne-API-security-demo-default-afwp'
var apimFirewallPolicyName    = 'SYS00X-azne-API-security-demo-afwp'
var logAnalyicsSettingsName   = 'SYS00X-azne-API-security-demo-appgw-logSettings'
var logAnalyticsName          = 'MyLogAnalyticsName'
var logAnalyticsResourceGroup = 'MyLogAnalyticsResourceGroup'

var backendAddressPoolName    = 'demo-apim'
var httpSettingName           = 'apim_443_httpsetting'

var environmentConfigurationMap = {
  DEV: {
    appGW: {
      sku: {
        name: 'Standard_v2'
        tier: 'Standard_v2'
      }
      autoscaleConfiguration: {
        minCapacity: 0
        maxCapacity: 2
      }
    }
  }
  TEST: {
    appGW: {
      sku: {
        name: 'WAF_v2'
        tier: 'WAF_v2'
      }
      autoscaleConfiguration: {
        minCapacity: 0
        maxCapacity: 2
      }
    }
  }
}

resource ThePublicIP 'Microsoft.Network/publicIPAddresses@2021-03-01' existing = {
  name: publicIpName
}

// Apim ref
resource ApimInstance 'Microsoft.ApiManagement/service@2021-04-01-preview' existing = {
  name: ApimInstanceName
  scope: resourceGroup(ApimInstanceResourceGroup)
}

resource AppGwNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' existing ={
  name: appGwNetworkName
}

resource ApimFirewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-03-01' = {
  name: apimFirewallPolicyName
  location: location
  tags: resourceGroup().tags
  properties: {
    policySettings:{
      requestBodyCheck: true
      maxRequestBodySizeInKb: 2000
      fileUploadLimitInMb: 10
      state: env == 'DEV' ? 'Disabled' : 'Enabled'
      mode: 'Prevention'
    }
    managedRules:{
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
      exclusions:[
        {
          selectorMatchOperator: 'StartsWith'
          selector: 'Authorization'
          matchVariable: 'RequestHeaderNames'
        }
      ]
    }
  } 
}

resource DefaultFirewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-03-01' = {
  name: defaultFirewallPolicyName
  location: location
  tags: resourceGroup().tags
  properties: {
    policySettings:{
      requestBodyCheck: false
      state: env == 'DEV' ? 'Disabled' : 'Enabled'
      mode: 'Prevention'
    }
    managedRules:{
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
      exclusions:[]
    }
  } 
}

resource AppGw 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: appGwName
  location: location
  tags: resourceGroup().tags
  
  properties: {
    
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101'
    }
    rewriteRuleSets: []
    sku: environmentConfigurationMap[env].appGW.sku
    autoscaleConfiguration: environmentConfigurationMap[env].appGW.autoscaleConfiguration
    enableHttp2: false
    
    gatewayIPConfigurations: [
      {
        name:'appGatewayIpConfig'
        properties:{
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', AppGwNetwork.name, AppGwNetwork.properties.subnets[1].name)
          }
        }
      }
    ]
    
    firewallPolicy: env != 'DEV' ? {
      id: DefaultFirewallPolicy.id
    } : null
    
    frontendIPConfigurations:[
      {
        name: 'appGwPublicFrontendIpIPv4'
        properties:{
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ThePublicIP.id
          }
        }
      }
    ]
    frontendPorts:[
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'sink'
        properties:{
          backendAddresses:[]
        }
      }
      {
        name: backendAddressPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: last(split(ApimInstance.properties.gatewayUrl,'/'))
            }
          ]
        }
      }
      
    ]
    probes:[
      {
        name:'apim_healthprobe'
        properties: {
          protocol:'Https'
          host: last(split(ApimInstance.properties.gatewayUrl,'/'))
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 10
          unhealthyThreshold:2
          pickHostNameFromBackendHttpSettings:false
          minServers:0
          match: {
            statusCodes:[
              '200'
            ]
          }        
        }
      }
    ]
    backendHttpSettingsCollection:[
      {
        name: httpSettingName
        properties:{
          port:443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwName, 'apim_healthprobe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'apim_80_listener'
        properties:{
          protocol: 'Http'
          
          frontendIPConfiguration:{
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort:{
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'port_80')
          }
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'apim_443'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',appGwName, backendAddressPoolName)
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',appGwName, httpSettingName)
          }
          pathRules: [
            {
              name:'sink'
              properties:{
                paths:[
                  '/*'
                ]
                backendAddressPool:{
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',appGwName, 'sink')
                }
                backendHttpSettings:{
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',appGwName, httpSettingName)
                }
              }
            }
            {
              name: 'apim_target'
              properties: {
                firewallPolicy: env != 'DEV' ? {
                  id: ApimFirewallPolicy.id
                } : null
                paths: [
                  '/echo/*'
                  '/train/v3/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',appGwName, backendAddressPoolName)
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',appGwName, httpSettingName)
                }                
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules:[
      {
        name: 'apim_443'
        properties:{
          ruleType:'PathBasedRouting'
          httpListener: {
            id:resourceId('Microsoft.Network/applicationGateways/httpListeners',appGwName,'apim_80_listener')
          }
          urlPathMap: {
            id:resourceId('Microsoft.Network/applicationGateways/urlPathMaps',appGwName,'apim_443')
          }
          
        }
      }
    ]
  }
}

// Logging
resource myLogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsName
  scope: resourceGroup(logAnalyticsResourceGroup)
}

resource LogAnalyticsConnection 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: logAnalyicsSettingsName
  scope: AppGw
  properties: {
    logAnalyticsDestinationType: 'Dedicated'
    workspaceId: myLogAnalytics.id
    logs: [
      { 
        enabled:true
        category: 'ApplicationGatewayAccessLog'
        retentionPolicy: {
          days: 30
          enabled:true 
        }
      }
      { 
        enabled:true
        category: 'ApplicationGatewayFirewallLog'
        retentionPolicy: {
          days: 30
          enabled:true 
        }
      }
    ]
  }
}
