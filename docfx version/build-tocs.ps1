$global:output = ""

function Process-DayFolder([String] $year, [String] $month, [String] $day) {
    $global:output += "    - name: $day`n      items:`n"

    $localPath = "./$year/$month/$day"
    $path = "./published/$localPath"
    $posts = Get-ChildItem -Path $path -Filter "*.md"
    foreach ($post in $posts) {
        $postName = (Get-Content "$path/$post" -First 1).Substring(2).Replace("'", "''")
        $global:output += "      - name: '${postName}'`n        href: $localPath/$post`n"
    }
}

function Process-MonthFolder([String] $year, [String] $month) {
    $global:output += "  - name: $month`n    items:`n"
    
    $dayFolders = Get-ChildItem -Path "./published/$year/$month" | Where-Object {$_.PSIsContainer}
    [array]::Reverse($dayFolders)
    foreach ($dayFolder in $dayFolders) {
        Process-DayFolder $year $month $dayFolder.Name
    }
}

function Process-YearFolder([String] $year) {
    $global:output += "- name: $year`n  items:`n"

    $monthFolders = Get-ChildItem -Path "./published/$year" | Where-Object {$_.PSIsContainer}
    [array]::Reverse($monthFolders)
    foreach ($monthFolder in $monthFolders) {
        Process-MonthFolder $year $monthFolder.Name
    }
}

$yearFolders = Get-ChildItem -Path "./published" | Where-Object {$_.PSIsContainer}
[array]::Reverse($yearFolders)
foreach ($yearFolder in $yearFolders) {
    Process-YearFolder $yearFolder.Name
}

Write-Output $global:output
Set-Content -Path "./published/toc.yml" -Value $global:output
