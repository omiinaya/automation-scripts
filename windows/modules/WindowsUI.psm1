<#
.SYNOPSIS
    Windows UI utility functions for consistent output and formatting.
.DESCRIPTION
    Provides functions for formatted console output, progress bars, and consistent UI presentation.
.NOTES
    File Name      : WindowsUI.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Function to write colored status messages
function Write-StatusMessage {
<#
.SYNOPSIS
    Writes a formatted status message to the console.
.DESCRIPTION
    Displays a message with consistent formatting and color coding based on status type.
.PARAMETER Message
    The message to display.
.PARAMETER Type
    The type of message (Info, Success, Warning, Error).
.PARAMETER NoNewline
    Don't add a newline at the end of the message.
.EXAMPLE
    Write-StatusMessage -Message "Operation completed" -Type Success
.EXAMPLE
    Write-StatusMessage -Message "Processing..." -Type Info -NoNewline
.EXAMPLE
    Write-StatusMessage -Message "Warning: Check configuration" -Type Warning
.OUTPUTS
    None. Writes to console.
.NOTES
    Colors: Info=Cyan, Success=Green, Warning=Yellow, Error=Red
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
    [ValidateSet("Info", "Success", "Warning", "Error")]
    [string]$Type = "Info",
    [switch]$NoNewline
)
    
    $colors = @{
        "Info"    = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error"   = "Red"
    }
    
    $prefixes = @{
        "Info"    = "[INFO]    "
        "Success" = "[SUCCESS] "
        "Warning" = "[WARNING] "
        "Error"   = "[ERROR]   "
    }
    
    $color = $colors[$Type]
    $prefix = $prefixes[$Type]
    
    Write-Host $prefix -ForegroundColor $color -NoNewline
    Write-Host $Message -ForegroundColor White -NoNewline:$NoNewline
}

# Function to write a section header
function Write-SectionHeader {
    <#
    .SYNOPSIS
        Writes a formatted section header.
    .DESCRIPTION
        Displays a section header with borders and consistent formatting.
    .PARAMETER Title
        The title of the section.
    .PARAMETER Width
        The width of the header (default: 60).
    .EXAMPLE
        Write-SectionHeader -Title "System Configuration"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [int]$Width = 60
    )
    
    $borderChar = "="
    $padding = " "
    $titleLength = $Title.Length
    $sidePadding = [math]::Floor(($Width - $titleLength - 2) / 2)
    
    $leftBorder = $borderChar * $sidePadding
    $rightBorder = $borderChar * ($Width - $sidePadding - $titleLength - 2)
    
    Write-Host ""
    Write-Host $borderChar * $Width -ForegroundColor Cyan
    Write-Host "$leftBorder$padding$Title$padding$rightBorder" -ForegroundColor Cyan
    Write-Host $borderChar * $Width -ForegroundColor Cyan
    Write-Host ""
}

# Function to write a progress bar
function Write-ProgressBar {
    <#
    .SYNOPSIS
        Writes a simple text-based progress bar.
    .DESCRIPTION
        Displays a progress bar in the console with percentage.
    .PARAMETER Percent
        The percentage complete (0-100).
    .PARAMETER Width
        The width of the progress bar (default: 40).
    .PARAMETER Activity
        Optional activity description.
    .EXAMPLE
        Write-ProgressBar -Percent 75 -Activity "Processing"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(0, 100)]
        [int]$Percent,
        [int]$Width = 40,
        [string]$Activity = ""
    )
    
    $filled = [math]::Round($Width * $Percent / 100)
    $empty = $Width - $filled
    
    $bar = "#" * $filled + "-" * $empty
    
    if ($Activity) {
        Write-Host "$Activity [$bar] $Percent%" -ForegroundColor Green
    } else {
        Write-Host "[$bar] $Percent%" -ForegroundColor Green
    }
}

# Function to display a menu
function Show-Menu {
    <#
    .SYNOPSIS
        Displays a selection menu.
    .DESCRIPTION
        Shows a numbered menu and returns the user's selection.
    .PARAMETER Title
        The title of the menu.
    .PARAMETER Options
        An array of menu options.
    .PARAMETER AllowMultiple
        Allow multiple selections (comma-separated).
    .EXAMPLE
        $choice = Show-Menu -Title "Select an option" -Options @("Option 1", "Option 2", "Option 3")
    .OUTPUTS
        System.Object
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [array]$Options,
        [switch]$AllowMultiple
    )
    
    Write-Host ""
    Write-SectionHeader -Title $Title
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $Options[$i]) -ForegroundColor White
    }
    
    Write-Host ""
    
    if ($AllowMultiple) {
        Write-Host "Enter your choices (comma-separated numbers): " -ForegroundColor Yellow -NoNewline
        $input = Read-Host
        $choices = $input -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
        return $choices | Where-Object { $_ -ge 0 -and $_ -lt $Options.Count }
    } else {
        Write-Host "Enter your choice (1-$($Options.Count)): " -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
        $index = [int]$choice - 1
        
        if ($index -ge 0 -and $index -lt $Options.Count) {
            return $Options[$index]
        } else {
            Write-StatusMessage -Message "Invalid selection" -Type Error
            return $null
        }
    }
}

# Function to display a confirmation prompt
function Show-Confirmation {
    <#
    .SYNOPSIS
        Shows a yes/no confirmation prompt.
    .DESCRIPTION
        Displays a confirmation message and returns true/false based on user input.
    .PARAMETER Message
        The confirmation message to display.
    .PARAMETER DefaultChoice
        The default choice (Yes, No).
    .EXAMPLE
        if (Show-Confirmation -Message "Continue with operation?") { Write-Host "Proceeding..." }
    .OUTPUTS
        System.Boolean
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("Yes", "No")]
        [string]$DefaultChoice = "No"
    )
    
    $yes = "Y"
    $no = "N"
    
    if ($DefaultChoice -eq "Yes") {
        $yes = "Y"
        $no = "n"
    } else {
        $yes = "y"
        $no = "N"
    }
    
    Write-Host "$Message [$yes/$no]: " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($DefaultChoice -eq "Yes") {
        return ($response -eq "" -or $response -eq "Y" -or $response -eq "y")
    } else {
        return ($response -eq "Y" -or $response -eq "y")
    }
}

# Function to display a table
function Show-Table {
<#
.SYNOPSIS
    Displays data in a formatted table.
.DESCRIPTION
    Shows an array of objects in a simple formatted table with auto-calculated column widths.
.PARAMETER Data
    The data to display. Should be an array of objects with properties.
.PARAMETER Title
    Optional table title.
.EXAMPLE
    $data = @([PSCustomObject]@{Name="Item1"; Value=100}, [PSCustomObject]@{Name="Item2"; Value=200})
    Show-Table -Data $data -Title "My Data"
.EXAMPLE
    Get-Process | Select-Object -First 5 Name, Id, CPU | Show-Table -Title "Running Processes"
.OUTPUTS
    None. Writes formatted table to console.
.NOTES
    Automatically calculates column widths based on data content.
#>
param(
    [Parameter(Mandatory=$true)]
    [array]$Data,
    [string]$Title = ""
)
    
    if ($Title) {
        Write-Host ""
        Write-Host $Title -ForegroundColor Cyan
        Write-Host ("-" * $Title.Length) -ForegroundColor Cyan
    }
    
    if ($Data.Count -eq 0) {
        Write-StatusMessage -Message "No data to display" -Type Warning
        return
    }
    
    # Get properties from the first object
    $properties = $Data[0].PSObject.Properties.Name
    
    # Calculate column widths
    $columnWidths = @{}
    foreach ($prop in $properties) {
        $maxWidth = [math]::Max($prop.Length, ($Data | ForEach-Object { $_.$prop.ToString().Length } | Measure-Object -Maximum).Maximum)
        $columnWidths[$prop] = [math]::Max($maxWidth, 10)
    }
    
    # Print header
    $header = ""
    foreach ($prop in $properties) {
        $header += "{0,-$($columnWidths[$prop])}  " -f $prop
    }
    Write-Host $header -ForegroundColor Cyan
    
    # Print separator
    $separator = ""
    foreach ($prop in $properties) {
        $separator += ("-" * $columnWidths[$prop]) + "  "
    }
    Write-Host $separator -ForegroundColor Cyan
    
    # Print data
    foreach ($item in $Data) {
        $row = ""
        foreach ($prop in $properties) {
            $row += "{0,-$($columnWidths[$prop])}  " -f $item.$prop
        }
        Write-Host $row -ForegroundColor White
    }
}

# Function to display a list with bullets
function Show-List {
    <#
    .SYNOPSIS
        Displays items in a bulleted list.
    .DESCRIPTION
        Shows items with bullet points and consistent formatting.
    .PARAMETER Items
        The items to display.
    .PARAMETER Title
        Optional list title.
    .EXAMPLE
        Show-List -Items @("Item 1", "Item 2", "Item 3") -Title "My List"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Items,
        [string]$Title = ""
    )
    
    if ($Title) {
        Write-Host ""
        Write-Host $Title -ForegroundColor Cyan
        Write-Host ("-" * $Title.Length) -ForegroundColor Cyan
    }
    
    foreach ($item in $Items) {
        Write-Host "  * $item" -ForegroundColor White
    }
}

# Function to pause execution
function Show-Pause {
    <#
    .SYNOPSIS
        Pauses execution and waits for user input.
    .DESCRIPTION
        Displays a pause message and waits for Enter key.
    .PARAMETER Message
        Custom pause message.
    .EXAMPLE
        Show-Pause -Message "Press Enter to continue..."
    #>
    param(
        [string]$Message = "Press Enter to continue..."
    )
    
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow -NoNewline
    $null = Read-Host
}

# Function to clear screen with header
function Clear-ScreenWithHeader {
    <#
    .SYNOPSIS
        Clears the screen and displays a header.
    .DESCRIPTION
        Clears the console and shows a title header.
    .PARAMETER Title
        The title to display.
    .EXAMPLE
        Clear-ScreenWithHeader -Title "Windows Administration Tool"
    #>
    param(
        [string]$Title = "Windows Administration Tool"
    )
    
    Clear-Host
    Write-SectionHeader -Title $Title -Width 80
    Write-Host ""
}

# Function to display system information banner
function Show-SystemBanner {
    <#
    .SYNOPSIS
        Displays a system information banner.
    .DESCRIPTION
        Shows current system information in a formatted banner.
    .EXAMPLE
        Show-SystemBanner
    #>
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem
    
    Write-Host ""
    Write-Host "+----------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|                        SYSTEM INFORMATION                      |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ("| Computer: {0,-52} |" -f $env:COMPUTERNAME) -ForegroundColor White
    Write-Host ("| User:     {0,-52} |" -f $env:USERNAME) -ForegroundColor White
    Write-Host ("| OS:       {0,-52} |" -f $os.Caption) -ForegroundColor White
    Write-Host ("| Version:  {0,-52} |" -f $os.Version) -ForegroundColor White
    Write-Host ("| Boot:     {0,-52} |" -f $computer.BootupState) -ForegroundColor White
    Write-Host "+----------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

# Export the module members
Export-ModuleMember -Function Write-StatusMessage, Write-SectionHeader, Write-ProgressBar, Show-Menu, Show-Confirmation, Show-Table, Show-List, Show-Pause, Clear-ScreenWithHeader, Show-SystemBanner