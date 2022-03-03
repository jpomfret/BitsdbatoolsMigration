#region words
# If we are not using the config files because they take too long even though they are the correct wya to do things
# we don't need this replace inhere
# [version]$dbachecksversioninconfig = (Get-DbcConfigValue -Name app.checkrepos).Split('/')[-1].Split('\')[0]
# [version]$dbachecksmodulevarsion = (Get-Module dbachecks).Version
# 
# if ($dbachecksmodulevarsion -ne $dbachecksversioninconfig) {
#   Get-ChildItem /workspace/Demos/dbachecksconfigs/*.json | ForEach-Object {
#     (Get-Content -Path $_.FullName) -replace $dbachecksversioninconfig, $dbachecksmodulevarsion | Set-Content $_.FullName
#   }
# }



function Start-Demo {
  

}
#>

function Set-ConnectionInfo {
  #region Set up connection
  $securePassword = ('dbatools.IO' | ConvertTo-SecureString -asPlainText -Force)
  $continercredential = New-Object System.Management.Automation.PSCredential('sqladmin', $securePassword)

  $Global:PSDefaultParameterValues = @{
    "*dba*:SqlCredential"            = $continercredential
    "*dba*:SourceSqlCredential"      = $continercredential
    "*dba*:DestinationSqlCredential" = $continercredential
    "*dba*:DestinationCredential"    = $continercredential
    "*dba*:PrimarySqlCredential"     = $continercredential
    "*dba*:SecondarySqlCredential"   = $continercredential
  }


  $containers = $SQLInstances = $dbatools1, $dbatools2 = 'dbatools1', 'dbatools2'
  #endregion
}

#Set-ConnectionInfo

function Set-FailedTestMessage {
  $FailedTests = ($results.FailedCount | Measure-Object -Sum).Sum
  if ($FailedTests -gt 0) {
    Write-PSFHostColor -String "NARRATOR - A thing went wrong" -DefaultColor DarkMagenta
    Write-PSFHostColor -String "NARRATOR - It MUST be fixed before we can continue" -DefaultColor DarkMagenta
    $Failures = $results.TestResult | Where Result -eq 'Failed'  | Select Describe, Context, Name, FailureMessage 
    $Failures.ForEach{
      $Message = '{0} at {1} in {2}' -f $_.FailureMessage, $_.Name, $_.Describe
      Write-PSFHostColor -String $Message -DefaultColor DarkCyan
    }
  }
}

function Assert-Correct {
  param (
    # Parameter help description
    [Parameter()]
    [ValidateSet(
      'initial',
      'Intro' ,
      'Backup',
      'Copy',
      'SnapShots',
      'Export',
      'Ags',
      'Found',
      'Masking',
      'Logins',
      'AdvMigration'
    )]
    [string]
    $chapter = 'initial'
  )
  $Global:PSDefaultParameterValues.CLear()
  switch ($chapter) {
    'initial' { 
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult

      Set-DbcConfig -Name app.sqlinstance -Value $containers
      Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      Set-DbcConfig -Name skip.connection.remoting -Value $true
      Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Verbose

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2'
      Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1'
      Set-DbcConfig -Name database.exists -Value 'pubs', 'NorthWind' -Append
      Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists

      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false  # reset
    }
    'Intro' { 
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Intro -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $null = Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2'
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Intro -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $null = Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1'
      $null = Set-DbcConfig -Name database.exists -Value 'pubs', 'NorthWind' -Append
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label Intro -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage

      Write-PSFHostColor -String "Are you ready to begin your adventure?" -DefaultColor Blue
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false  # reset
    }
    'Backup' { 
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      $null = Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers 
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL' 
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true 
      $null = Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' 

      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Backup -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $null = Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' 
      $null = Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'tempdb' 

      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, NoDatabasesOn1, NoBackupFiles -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Backup -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $results = @($check1, $check2)
      Set-FailedTestMessage
      Write-PSFHostColor -String "Should you create a save point before this chapter?" -DefaultColor Blue
      Start-Sleep -Seconds 5
      Write-PSFHostColor -String "Or can you make it to the end?" -DefaultColor DarkRed
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false # reset

    }
    'Copy' { 
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      $null = Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append
      Set-DbcConfig -Name app.sqlinstance -Value $containers  | Out-Null
      Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'  | Out-Null
      Set-DbcConfig -Name skip.connection.remoting -Value $true  | Out-Null
      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null

      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, NoDatabasesOn2, NeedNoLogins -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Copy -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'pubs-0', 'pubs-1', 'pubs-10', 'pubs-2', 'pubs-3', 'pubs-4', 'pubs-5', 'pubs-6', 'pubs-7', 'pubs-8', 'pubs-9', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Copy -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $results = @($check1, $check2)
      Set-FailedTestMessage
      Write-PSFHostColor -String "If you get database missing failures - Chapter 2 will be your friend" -DefaultColor Magenta
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false # reset
    }
    'Snapshots' { 
      # Valid estate is as we expect
      Write-PSFHostColor -String "Running the SnapShot Chapter checks" -DefaultColor Green
      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append | Out-Null
      Set-DbcConfig -Name app.sqlinstance -Value $containers  | Out-Null
      Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'  | Out-Null
      Set-DbcConfig -Name skip.connection.remoting -Value $true  | Out-Null
      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, NoDatabasesOn2, DatabaseStatus, NoSnapshots -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label SnapShots -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, DatabaseStatus -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label SnapShots -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      $results = @($check1, $check2)
      Set-FailedTestMessage
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false # reset
    }
    'Export' { 
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Export -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $null = Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2'
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Export -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      $null = Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1'
      $null = Set-DbcConfig -Name database.exists -Value 'pubs', 'NorthWind' -Append
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label Export -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false
    }
    'Ags' { 
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      $null = Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append | Out-Null
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label AvailabilityGroups -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, NoDatabasesOn2, DatabaseStatus, NoSnapshots, NoAgs -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label AvailabilityGroups -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'pubs-0', 'pubs-1', 'pubs-10', 'pubs-2', 'pubs-3', 'pubs-4', 'pubs-5', 'pubs-6', 'pubs-7', 'pubs-8', 'pubs-9', 'tempdb' | Out-Null
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, DatabaseStatus -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label AvailabilityGroups -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
      Write-PSFHostColor -String "If you get database missing failures - Chapter 2 will be your friend" -DefaultColor Magenta
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false
    }
    'AdvMigration' {
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append | Out-Null
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label AdvancedMigration -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, NoDatabasesOn2, DatabaseStatus, NoSnapshots, NoAgs -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label AdvancedMigration -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'tempdb' | Out-Null
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, DatabaseStatus -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label AdvancedMigration -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false
    }
    'Found' {
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append | Out-Null
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Found -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists,NeedJobs, NeedFailedJobs  -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Found -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'tempdb' | Out-Null
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, DatabaseStatus, NeedSps,NeedUDfs,NeedTriggers,NeedLogins -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label Found -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false
    }
    'Masking' {
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append | Out-Null
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Masking -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Masking -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'tempdb' | Out-Null
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, DatabaseStatus -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label Masking -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false
    }
    'Logins' {
      # Valid estate is as we expect

      $null = Reset-DbcConfig 
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $true  # so we dont get silly output from convert-dbcresult
      Set-DbcConfig -Name app.checkrepos -Value '/workspace/Demos/dbachecksconfigs' -Append | Out-Null
      $null = Set-DbcConfig -Name app.sqlinstance -Value $containers
      $null = Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'
      $null = Set-DbcConfig -Name skip.connection.remoting -Value $true
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection -Show Summary -PassThru
      $check1 | Convert-DbcResult -Label Logins -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools2' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'tempdb' | Out-Null
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists -Show Summary -PassThru
      $check2 | Convert-DbcResult -Label Logins -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 

      Set-DbcConfig -Name app.sqlinstance -Value 'dbatools1' | Out-Null
      Set-DbcConfig -Name database.exists -Value 'master', 'model', 'msdb', 'Northwind', 'pubs', 'tempdb' | Out-Null
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection, DatabaseExists, DatabaseStatus -Show Summary -PassThru
      $check3 | Convert-DbcResult -Label Logins -warningaction SilentlyContinue | Write-DbcTable -SqlInstance $dbatools1 -SqlCredential $continercredential  -Database Validation 
      
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
      $null = Set-PSFConfig -FullName PSFramework.Message.ConsoleOutput.Disable -value $false
    }
    Default {
      # Valid estate is as we expect

      $null = Reset-DbcConfig 

      $null = Import-DbcConfig /workspace/Demos/dbachecksconfigs/initial-config.json
      $check3 = Invoke-DbcCheck -SqlCredential $continercredential -Check InstanceConnection  -Show Summary -PassThru

      $null = Reset-DbcConfig 

      $null = Import-DbcConfig /workspace/Demos/dbachecksconfigs/initial-dbatools1-config.json
      $check2 = Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists -Show Summary -PassThru

      $null = Reset-DbcConfig 

      $null = Import-DbcConfig /workspace/Demos/dbachecksconfigs/initial-dbatools2-config.json
      $check1 = Invoke-DbcCheck -SqlCredential $continercredential -Check DatabaseExists -Show Summary -PassThru
      $results = @($check1, $check2, $check3)
      Set-FailedTestMessage
    }
  }
  $Global:PSDefaultParameterValues = @{
    "*dba*:SqlCredential"            = $continercredential
    "*dba*:SourceSqlCredential"      = $continercredential
    "*dba*:DestinationSqlCredential" = $continercredential
    "*dba*:DestinationCredential"    = $continercredential
    "*dba*:PrimarySqlCredential"     = $continercredential
    "*dba*:SecondarySqlCredential"   = $continercredential
  }
}

function Invoke-PubsApplication {
  # This will randomly insert rows into the pubs.dbo.sales table on dbatools1 to simulate sales activity
  # It'll run until you kill it
  
  #Write-PSFHostColor -String "Pubs application is running...forever... Ctrl+C to get out of here" -DefaultColor Green

  # app connection
  $securePassword = ('PubsAdmin' | ConvertTo-SecureString -asPlainText -Force)
  $appCred = New-Object System.Management.Automation.PSCredential('PubsAdmin', $securePassword)
  $appConnection = Connect-DbaInstance -SqlInstance $dbatools1 -SqlCredential $appCred -ClientName 'PubsApplication'

  while ($true) {   
    $newOrder = [PSCustomObject]@{
      stor_id  = Get-Random (Invoke-DbaQuery -SqlInstance $appConnection -Database pubs -Query 'select stor_id from stores').stor_id
      ord_num  = Get-DbaRandomizedValue -DataType int -Min 1000 -Max 99999
      ord_date = get-date
      qty      = Get-Random -Minimum 1 -Maximum 30
      payterms = Get-Random (Invoke-DbaQuery -SqlInstance $appConnection -Database pubs -Query 'select distinct payterms from pubs.dbo.sales').payterms
      title_id = Get-Random (Invoke-DbaQuery -SqlInstance $appConnection -Database pubs -Query 'select title_id from titles').title_id
    }
    Write-DbaDataTable -SqlInstance $appConnection -Database pubs -InputObject $newOrder -Table sales
    
    Start-sleep -Seconds (Get-Random -Maximum 10)
  }
}

