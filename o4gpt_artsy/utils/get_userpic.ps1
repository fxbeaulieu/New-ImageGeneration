$ExportImagePath = "$PSScriptRoot\.."
$SID=(Get-WmiObject win32_useraccount | Select-Object name, sid | Where-Object -Property Name -like $ENV:USERNAME |Select-Object -Property SID).SID
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$SID\"
$ProfilePicturePath = Get-ItemPropertyValue -Path $RegPath -Name Image96
Copy-Item -Path $ProfilePicturePath -Destination "$ExportImagePath\user_pic.jpg" -Force
Get-ChildItem -Path "$ExportImagePath" -Filter "*.jpg" -Force | Where-Object {$_.Attributes -match "Hidden"} | ForEach-Object { $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden) }
Get-ChildItem -Path "$ExportImagePath" -Filter "*.jpg" -Force | Where-Object {$_.Attributes -match "System"} | ForEach-Object { $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::System) }