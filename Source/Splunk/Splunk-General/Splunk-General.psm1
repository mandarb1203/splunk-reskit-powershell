
#region General functions

#region Write-SplunkMessage

function Write-SplunkMessage
{
	<# .ExternalHelp ../Splunk-Help.xml #>

    [Cmdletbinding()]
    Param(
        
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]           
        [String]$HostName     = $Env:COMPUTERNAME,
        
        [Parameter()]           
        [String]$Source       = "Powershell_Script",
        
        [Parameter()]           
        [String]$SourceType   = "Splunk_SDK_PowerShell",
        
        [Parameter()]           
        [String]$Index        = "main",
        
        [Parameter()]           
        [String]$Message,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = ( get-splunkconnectionobject ).Credential
        
    )

	Begin
	{
		Write-Verbose " [Write-SplunkMessage] :: Starting..."
        $Stack = Get-PSCallStack
        $CallingScope = $Stack[$Stack.Count-2]
	}
	Process
	{
		Write-Verbose " [Write-SplunkMessage] :: Parameters"
		Write-Verbose " [Write-SplunkMessage] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Write-SplunkMessage] ::  - Port         = $Port"
		Write-Verbose " [Write-SplunkMessage] ::  - Protocol     = $Protocol"
		Write-Verbose " [Write-SplunkMessage] ::  - Timeout      = $Timeout"
		Write-Verbose " [Write-SplunkMessage] ::  - Credential   = $Credential"

		Write-Verbose " [Write-SplunkMessage] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/services/receivers/simple' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
        
        
                    
		Write-Verbose " [Write-SplunkMessage] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
            Write-Verbose " [Write-SplunkMessage] :: Creating POST message"
            $LogMessage = "{0} :: Caller={1} Message={2}" -f (Get-Date),$CallingScope.Command,$Message
            
            $MyParam = "host=${HostName}&source=${source}&sourcetype=${sourcetype}&index=$Index"
            Write-Verbose " [Write-SplunkMessage] :: URL Parameters [$MyParam]"
            
            Write-Verbose " [Write-SplunkMessage] :: Sending LogMessage - $LogMessage"
			[XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams -PostMessage $LogMessage -URLParam $MyParam -RequestType SIMPLEPOST
        }
        catch
		{
			Write-Verbose " [Write-SplunkMessage] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
                $Myobj = @{}

                foreach($key in $Results.response.results.result.field)
                {
                    $data = $key.Value.Text
                    switch -exact ($Key.k)
                    {
                        "_index"       {$Myobj.Add("Index",$data);continue}
                        "host"         {$Myobj.Add("Host",$data);continue}
                        "source"       {$Myobj.Add("Source",$data);continue} 
                        "sourcetype"   {$Myobj.Add("Sourcetype",$data);continue}
                    }
                }
                
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('Splunk.SDK.MessageResult')
                $obj
			}
			else
			{
				Write-Verbose " [Write-SplunkMessage] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Write-SplunkMessage] :: Get-Splunkd threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Write-SplunkMessage] :: =========    End   ========="
	}
    
}    # Write-SplunkMessage

#endregion Write-SplunkMessage

#endregion General functions
