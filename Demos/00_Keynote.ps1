<#
    ( )( )           ( )_               (_ )       
    _| || |_      _ _ | ,_)   _      _    | |   ___ 
/'_` || '_`\  /'_` )| |   /'_`\  /'_`\  | | /',__)
( (_| || |_) )( (_| || |_ ( (_) )( (_) ) | | \__, \
`\__,_)(_,__/'`\__,_)`\__)`\___/'`\___/'(___)(____/
#>

# A community module
# Command line SSMS

# 526 Commands - in only 5 mins!?!
Get-Command -Module dbatools -CommandType Function | Measure-Object | Select-Object Count

# Let's do a Top 5

# 5. Get-DbaDatabase - Grab some details about your databases
Get-DbaDatabase -SqlInstance $SQLInstances | Select-Object SqlInstance, Name, Status, RecoveryModel, Owner, AutoClose | Format-Table

# 4. Test-DbaBuild - Are me SQL Servers patched?
Test-DbaBuild -SqlInstance $SQLInstances -Latest | Format-Table

# 3. Get-DbaAgentJob - Check for any failures
Get-DbaAgentJob -SqlInstance $SQLInstances | Sort-Object LastRunDate -Desc | Format-Table SqlInstance, Name, LastRunDate, LastRunOutcome

# 2. Backup & then Test those backups!
Backup-DbaDatabase -SqlInstance $dbatools1
Test-DbaLastBackup -SqlInstance $dbatools1 -Destination $dbatools2 | Format-Table

# 1. Copy-DbaDatabase - Migrate databases so easily
Get-DbaDatabase -SqlInstance $SQLInstances -ExcludeSystem | Select-Object SqlInstance, Name, Status | Format-Table

Copy-DbaDatabase -Source $dbatools1 -Destination $dbatools2 -Database Northwind, pubs -BackupRestore -SharedPath '/shared' -SetSourceOffline

Get-DbaDatabase -SqlInstance $SQLInstances  -ExcludeSystem | Select-Object SqlInstance, Name, Status | Format-Table
