#$computernames = @("MU57470","MU57471","MU57472","MU57473","MU57474","MU57475","MU57476","MU57477")   # place computername here for remote access
$computernames = @("MU57473") 
$username = 'student'
$password = '$tudent16'
#$desc = 'Automatically created local admin account'

foreach($computername in $computernames) {
$computer = [ADSI]"WinNT://$computername,computer"
$user = $computer.Create("user", $username)
$user.SetPassword($password)
$user.Setinfo()
#$user.description = $desc
#$user.setinfo()
$user.UserFlags = 65536
$user.SetInfo()
$group = [ADSI]("WinNT://$computername/administrators,group")
$group.add("WinNT://$username,user")
}