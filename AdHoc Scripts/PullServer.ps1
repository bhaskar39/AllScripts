configuration Sample_xDscWebService
{
    param
    (
        [string[]]$NodeName = 'WIN-2LADSKQ28VD',
        [ValidateNotNullOrEmpty()]
        [string] $certificateThumbPrint = "AllowUnencryptedTraffic"
    )

    Import-DSCResource -ModuleName PSDesiredStateConfiguration,xPSDesiredStateConfiguration

    Node $NodeName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name = "DSC-Service"
        }

        WindowsFeature WinAuth
        {
            Ensure = "Present"
            Name = "web-Windows-Auth"
        }

        xDscWebService PSDSCPullServer
        {
            Ensure = "Present"
            EndpointName = "PullSvc"
            Port = 8080
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint = $certificateThumbPrint
            ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State = "Started"
            DependsOn = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer
        {
            Ensure = "Present"
            EndpointName = "DscConformance"
            Port = 9090
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            CertificateThumbPrint = "AllowUnencryptedTraffic"
            State = "Started"
            DependsOn = @("[WindowsFeature]DSCServiceFeature","[WindowsFeature]WinAuth","[xDSCWebService]PSDSCPullServer")
        }
    }
}
Sample_xDscWebService

Configuration SimpleMetaConfigurationForPull
{

Param(
[Parameter(Mandatory=$True)]
[String]$NodeGUID
)

LocalConfigurationManager
{
ConfigurationID = $NodeGUID;
RefreshMode = "PULL";
DownloadManagerName = "WebDownloadManager";
RebootNodeIfNeeded = $true;
RefreshFrequencyMins = 15;
ConfigurationModeFrequencyMins = 30;
ConfigurationMode = "ApplyAndAutoCorrect";
DownloadManagerCustomData = @{ServerUrl = "http://Server1.mycompany.com:8080/PullSvc/PSDSCPullServer.svc"; AllowUnsecureConnection = “TRUE”}
}
}