$server = new-Object Microsoft.SqlServer.Management.Smo.Server("(local)")
$db = New-Object Microsoft.SqlServer.Management.Smo.Database($server, 'TestDB')
$db.Create()

$login = new-object Microsoft.SqlServer.Management.Smo.Login("(local)", 'TestUser')
$login.LoginType = 'SqlLogin'
$login.PasswordPolicyEnforced = $false
$login.PasswordExpirationEnabled = $false
$login.Create('Password1')

$server = new-Object Microsoft.SqlServer.Management.Smo.Server("(local)")
$db = New-Object Microsoft.SqlServer.Management.Smo.Database
$db = $server.Databases.Item('TestDB')
$db.SetOwner('TestUser', $TRUE)
$db.Alter()
Invoke-Sqlcmd -ServerInstance localhost -Database 'TestDB' -Username 'TestUser' -Password 'Password1' -Query "SELECT * FROM sysusers"