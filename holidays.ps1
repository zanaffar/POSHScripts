$height = 11
$Message = "Happy Holidays from Max!!`n"
$Message2 = "`n...can you tell that`n"
$Message3 = "I'm working on projects`n"
$Message4 = "that really matter? :)`n"

0..($height-1) | % { Write-Host ' ' -NoNewline }
Write-Host -ForegroundColor Yellow '☆'
0..($height - 1) | %{
    $width = $_ * 2 
    1..($height - $_) | %{ Write-Host ' ' -NoNewline}

    Write-Host '/' -NoNewline -ForegroundColor Green
    while($Width -gt 0){
        switch (Get-Random -Minimum 1 -Maximum 20) {
            1       { Write-Host -BackgroundColor Green -ForegroundColor Red '@' -NoNewline }
            2       { Write-Host -BackgroundColor Green -ForegroundColor Green '@' -NoNewline }
            3       { Write-Host -BackgroundColor Green -ForegroundColor Blue '@' -NoNewline }
            4       { Write-Host -BackgroundColor Green -ForegroundColor Yellow '@' -NoNewline }
            5       { Write-Host -BackgroundColor Green -ForegroundColor Magenta '@' -NoNewline }
            Default { Write-Host -BackgroundColor Green ' ' -NoNewline }
        }
        $Width--
    }
     Write-Host '\' -ForegroundColor Green
}
0..($height*2) | %{ Write-Host -ForegroundColor Green '~' -NoNewline }
Write-Host -ForegroundColor Green '~'
0..($height-1) | % { Write-Host ' ' -NoNewline }
Write-Host -BackgroundColor Black -ForegroundColor Black ' '
$Padding = ($Height * 2 - $Message.Length + 1) / 2
if($Padding -gt 0){
    1..$Padding | % { Write-Host ' ' -NoNewline }
}
0..($Message.Length -1) | %{
    $Index = $_
    switch ($Index % 2 ){
        0 { Write-Host -ForegroundColor Green $Message[$Index] -NoNewline }
        1 { Write-Host -ForegroundColor Red $Message[$Index] -NoNewline }
    }
}
$Padding = ($Height * 2 - $Message2.Length + 1) / 2
if($Padding -gt 0){
    1..$Padding | % { Write-Host ' ' -NoNewline }
}
0..($Message2.Length -1) | %{
    $Index = $_
    Write-Host -ForegroundColor Green $Message2[$Index] -NoNewline
}
$Padding = ($Height * 2 - $Message3.Length + 1) / 2
if($Padding -gt 0){
    1..$Padding | % { Write-Host ' ' -NoNewline }
}
0..($Message3.Length -1) | %{
    $Index = $_
    Write-Host -ForegroundColor Green $Message3[$Index] -NoNewline
}
$Padding = ($Height * 2 - $Message4.Length) / 2
if($Padding -gt 0){
    1..$Padding | % { Write-Host ' ' -NoNewline }
}
0..($Message4.Length -1) | %{
    $Index = $_
    Write-Host -ForegroundColor Green $Message4[$Index] -NoNewline
}  

function Pause

{

   Read-Host "`nPress Enter to close…" | Out-Null

}

Pause