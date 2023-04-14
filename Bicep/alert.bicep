var ApimInstanceName    = 'MyAPImInstance'
var ActionGroupName     = 'MyActionGroup'
var ActionGroupRGName   = 'MyActionGroupResourceGroup'

var alert40XName        = 'MyAPImInstance-Sudden40X'
var alertThrottlingName = 'MyAPImInstance-Throttling'

resource actionGroup 'microsoft.insights/actionGroups@2019-06-01' existing = {
  name: ActionGroupName
  scope: resourceGroup(ActionGroupRGName)
}

resource apimInstance 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: ApimInstanceName
}

resource metricAlerts_Sudden_uptick_in_40x_name_resource 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: alert40XName
  location: 'global'
  tags: resourceGroup().tags
  properties: {
    description: 'APIm has detected an unusual amount of 401 and 403'
    severity: 2
    enabled: true
    scopes: [
      apimInstance.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          alertSensitivity: 'Low'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 4
          }
          ignoreDataBefore: '2022-08-14T22:00:00.000Z'
          name: 'Metric1'
          metricNamespace: 'Microsoft.ApiManagement/service'
          metricName: 'Requests'
          dimensions: [
            {
              name: 'GatewayResponseCode'
              operator: 'Include'
              values: [
                '401'
                '403'                
              ]
            }
          ]
          operator: 'GreaterOrLessThan'
          timeAggregation: 'Total'
          criterionType: 'DynamicThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    autoMitigate: false
    targetResourceType: 'Microsoft.ApiManagement/service'
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {
        }
      }
    ]
  }
}

resource metricAlerts_Throttling_429 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: alertThrottlingName
  location: 'global'
  tags: resourceGroup().tags
  properties: {
    description: 'We are responding with > 5 429 the last minute. There might be an issue. Might be a backend problem.'
    severity: 1
    enabled: true
    scopes: [
      apimInstance.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          threshold: 5
          name: 'Metric1'
          metricNamespace: 'Microsoft.ApiManagement/service'
          metricName: 'Requests'
          dimensions: [
            {
              name: 'GatewayResponseCode'
              operator: 'Include'
              values: [
                '429'
              ]
            }
          ]
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.ApiManagement/service'
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {
        }
      }
    ]
  }
}
