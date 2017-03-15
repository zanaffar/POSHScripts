#region XAML window definition
# Right-click XAML and choose WPF/Edit... to edit WPF Design
# in your favorite WPF editing tool
$xaml = @'

<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   MinWidth="200"
   Width="400"
   SizeToContent="Height"
   Title="New Mail"
   Topmost="True">
   <Grid Margin="10,40,10,10">
      <Grid.ColumnDefinitions>
         <ColumnDefinition Width="Auto"/>
         <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <Grid.RowDefinitions>
         <RowDefinition Height="Auto"/>
         <RowDefinition Height="Auto"/>
         <RowDefinition Height="Auto"/>
         <RowDefinition Height="*"/>
      </Grid.RowDefinitions>
      <TextBlock
         Grid.Column="0"
         Grid.ColumnSpan="2"
         Grid.Row="0"
         Margin="5">Please enter your details:
      
      
      
      </TextBlock>
      <TextBlock Grid.Column="0" Grid.Row="1" Margin="5">Name
      
      
      
      </TextBlock>
      <TextBlock Grid.Column="0" Grid.Row="2" Margin="5">Email
      
      
      
      </TextBlock>
      <TextBox
         Name="TxtName"
         Grid.Column="1"
         Grid.Row="1"
         Margin="5">
      </TextBox>
      <TextBox
         Name="TxtEmail"
         Grid.Column="1"
         Grid.Row="2"
         Margin="5">
      </TextBox>
      <StackPanel
         Grid.ColumnSpan="2"
         Grid.Row="3"
         HorizontalAlignment="Right"
         Margin="0,10,0,0"
         VerticalAlignment="Bottom"
         Orientation="Horizontal">
         <Button
            Name="ButOk"
            Height="22"
            MinWidth="80"
            Margin="5">OK
         
         
         
         </Button>
         <Button
            Name="ButCancel"
            Height="22"
            MinWidth="80"
            Margin="5">Cancel
         
         
         
         </Button>
      </StackPanel>
   </Grid>
</Window>

'@
#endregion

#region Code Behind
function Convert-XAMLtoWindow
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $XAML,
    
    [string[]]
    $NamedElement=$null,
    
    [switch]
    $PassThru
  )
  
  Add-Type -AssemblyName PresentationFramework
  
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  foreach($Name in $NamedElement)
  {
    $result | Add-Member NoteProperty -Name $Name -Value $result.FindName($Name) -Force
  }
  
  if ($PassThru)
  {
    $result
  }
  else
  {
    $null = $window.Dispatcher.InvokeAsync{
      $result = $window.ShowDialog()
      Set-Variable -Name result -Value $result -Scope 1
    }.Wait()
    $result
  }
}

function Show-WPFWindow
{
  param
  (
    [Parameter(Mandatory)]
    [Windows.Window]
    $Window
  )
  
  $result = $null
  $null = $window.Dispatcher.InvokeAsync{
    $result = $window.ShowDialog()
    Set-Variable -Name result -Value $result -Scope 1
  }.Wait()
  $result
}
#endregion Code Behind

#region Convert XAML to Window
$window = Convert-XAMLtoWindow -XAML $xaml -NamedElement 'ButCancel', 'ButOk', 'TxtEmail', 'TxtName' -PassThru
#endregion

#region Define Event Handlers
# Right-Click XAML Text and choose WPF/Attach Events to
# add more handlers
$window.ButCancel.add_Click(
  {
    $window.DialogResult = $false
  }
)

$window.ButOk.add_Click(
  {
    $window.DialogResult = $true
    & "$env:windir\system32\notepad.exe"
  }
)
$window.ButOk.add_KeyDown{
  # remove param() block if access to event information is not required
  param
  (
    [Parameter(Mandatory)][Object]$sender,
    [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
  )
  
  # add event code here
  
}

#endregion Event Handlers

#region Manipulate Window Content
$window.TxtName.Text = $env:username
$window.TxtEmail.Text = 'test@test.com'
$null = $window.TxtName.Focus()
#endregion

# Show Window
$result = Show-WPFWindow -Window $window

#region Process results
if ($result -eq $true)
{
  $hash = [Ordered]@{
    EmployeeName = $window.TxtName.Text
    EmployeeMail = $window.TxtEmail.Text
  }
  New-Object -TypeName PSObject -Property $hash
}
else
{
  Write-Warning 'User aborted dialog.'
}
#endregion Process results