Add-Type -AssemblyName System.Windows.Forms

    function Show-ConfirmationDialog {
        param (
            [string]$message,
            [string]$title
        )

        $msgBoxInput = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

        if ($msgBoxInput -eq [System.Windows.Forms.DialogResult]::Yes) {
            return $true
        } else {
            return $false
        }
    }

    function Show-CommandConfirmationDialog {
        param (
            [string]$message,
            [string]$title
        )

        $msgBoxInput = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Information)

        if ($msgBoxInput -eq [System.Windows.Forms.DialogResult]::OK) {
            return $true
        } else {
            return $false
        }
    }

    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Text = "Usuwanie uprawnień"
    $mainForm.Size = New-Object System.Drawing.Size(500, 400)

    $labelPath = New-Object System.Windows.Forms.Label
    $labelPath.Text = "Wprowadź ścieżkę do katalogu głównego:"
    $labelPath.Location = New-Object System.Drawing.Point(10, 10)
    $labelPath.Width = 300
    $labelPath.Height = 15
    $mainForm.Controls.Add($labelPath)

    $textBoxPath = New-Object System.Windows.Forms.TextBox
    $textBoxPath.Location = New-Object System.Drawing.Point(10, 30)
    $textBoxPath.Size = New-Object System.Drawing.Size(400, 20)
    $mainForm.Controls.Add($textBoxPath)
    # Przycisk "Zatwierdź" pod pierwszym polem tekstowym
    $buttonSubmitPath = New-Object System.Windows.Forms.Button
$buttonSubmitPath.Text = "Zatwierdź"
$buttonSubmitPath.Location = New-Object System.Drawing.Point(10, 60)

# Pole tekstowe z dostępnymi podfolderami danego folderu
$availableDirectoriesTextBox = New-Object System.Windows.Forms.TextBox
$availableDirectoriesTextBox.Location = New-Object System.Drawing.Point(230, 230)
$availableDirectoriesTextBox.Size = New-Object System.Drawing.Size(200, 60)
$availableDirectoriesTextBox.Multiline = $true
$availableDirectoriesTextBox.ScrollBars = "Both"
$mainForm.Controls.Add($availableDirectoriesTextBox)

# Dodaj inicjalizację $availableGroupsTextBox
$availableGroupsTextBox = New-Object System.Windows.Forms.TextBox
$availableGroupsTextBox.Location = New-Object System.Drawing.Point(10, 230)
$availableGroupsTextBox.Size = New-Object System.Drawing.Size(200, 60)
$availableGroupsTextBox.Multiline = $true
$availableGroupsTextBox.ScrollBars = "Both"
$mainForm.Controls.Add($availableGroupsTextBox)

$buttonSubmitPath.Add_Click({
    $directory = $textBoxPath.Text

    # Sprawdzenie, czy wprowadzony tekst jest poprawną ścieżką katalogu
    if (Test-Path $directory -PathType Container) {
        $directories = Get-ChildItem $directory | ForEach-Object { (Get-Acl $_.FullName).Access | Where-Object { $_.IdentityReference -is [System.Security.Principal.NTAccount] } | Select-Object -ExpandProperty IdentityReference } | ForEach-Object { $_.ToString().ToLower() } | Select-Object -Unique
        $folders = (Get-ChildItem $directory -Directory).FullName
        foreach ($dir in $directories) {
            write-host $dir
            $availableGroupsTextBox.AppendText("$dir`r`n")  # Dodaj wyniki do $availableGroupsTextBox z nową linią po każdym wyniku
        }
        foreach($f in $folders)
        {
            $availableDirectoriesTextBox.AppendText("$f`r`n")
        }
        $buttonInheritance.Enabled = $true
    } else {
        # Jeśli wprowadzony tekst nie jest poprawną ścieżką katalogu, wyświetl komunikat
        [System.Windows.Forms.MessageBox]::Show("Wprowadzona ścieżka nie jest poprawna.", "Błąd", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$mainForm.Controls.Add($buttonSubmitPath)


    $labelGroups = New-Object System.Windows.Forms.Label
    $labelGroups.Text = "Wprowadź grupy do usunięcia uprawnień:"
    $labelGroups.Location = New-Object System.Drawing.Point(10, 90)
    $labelGroups.Width = 300
    $labelGroups.Height = 15
    $mainForm.Controls.Add($labelGroups)

    $textBoxGroups = New-Object System.Windows.Forms.TextBox
    $textBoxGroups.Location = New-Object System.Drawing.Point(10, 110)
    $textBoxGroups.Size = New-Object System.Drawing.Size(400, 20)
    $mainForm.Controls.Add($textBoxGroups)

   # Przycisk "Zatwierdź komendę" pod drugim polem tekstowym
$buttonSubmitCommand = New-Object System.Windows.Forms.Button
$buttonSubmitCommand.Text = "Zatwierdź komendę"
$buttonSubmitCommand.Location = New-Object System.Drawing.Point(10, 140)
$buttonSubmitCommand.Width = 150
$buttonSubmitCommand.Add_Click({
    $command = $textBoxGroups.Text
    $availableGroups = $resultsTextBox.Text -split "`r`n" | Where-Object { $_.Trim() -ne "" }

    # Sprawdzenie, czy wprowadzona grupa istnieje wśród dostępnych grup
    if ($availableGroups -contains $command) {
        $confirmMessage = "Czy na pewno chcesz usunąć uprawnienia dla grupy $command z folderów?"
        $confirmTitle = "Potwierdzenie usunięcia uprawnień"
        $confirmResult = Show-ConfirmationDialog -message $confirmMessage -title $confirmTitle

        if ($confirmResult) {
            ForEach ($dir in (Get-ChildItem $textBoxPath.Text -Recurse).FullName) {
                $acl = Get-Acl $dir
                $acl.Access | Where-Object { $_.IdentityReference.Value -eq $command } | ForEach-Object { $acl.RemoveAccessRule($_) }
                Set-Acl -Path $dir -AclObject $acl
            }

            # Po usunięciu uprawnień, zaktualizuj listę dostępnych grup
            UpdateAvailableGroupsList
        } else {
            # Jeśli potwierdzenie nie zostało udzielone, wyświetl komunikat
            [System.Windows.Forms.MessageBox]::Show("Operacja usunięcia uprawnień została anulowana.", "Anulowano", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } else {
        # Jeśli wprowadzona grupa nie istnieje, wyświetl komunikat o błędzie
        [System.Windows.Forms.MessageBox]::Show("Wprowadzona grupa nie istnieje.", "Błąd", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$mainForm.Controls.Add($buttonSubmitCommand)

    # Przycisk "Dziedziczenie" pod drugim polem tekstowym
    $buttonInheritance = New-Object System.Windows.Forms.Button
    $buttonInheritance.Text = "Dziedziczenie"
    $buttonInheritance.Location = New-Object System.Drawing.Point(10, 170)
    $buttonInheritance.Width = 150
    $buttonInheritance.Enabled = $null  # Ustaw na stan nieokreślony
    $buttonInheritance.Add_Click({
        # Sprawdź, czy wprowadzono ścieżkę
        if ($textBoxPath.Text -eq "") {
            [System.Windows.Forms.MessageBox]::Show("Aby usunąć dziedziczenie, wprowadź ścieżkę do katalogu.", "Brak ścieżki", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }

        $confirmMessage = "Czy chcesz wyłączyć dziedziczenie?"
        $confirmTitle = "Potwierdzenie"
        $result = Show-ConfirmationDialog -message $confirmMessage -title $confirmTitle

        if ($result) {
            $commandConfirmMessage = "Czy na pewno chcesz wyłączyć dziedziczenie?"
            $commandConfirmTitle = "Potwierdzenie komendy"
            $commandResult = Show-CommandConfirmationDialog -message $commandConfirmMessage -title $commandConfirmTitle

            if ($commandResult) {
                # Tutaj dodaj logikę dla wyłączenia dziedziczenia
                $confirmationResult = foreach($dir in (Get-ChildItem $textBoxPath.Text).FullName ) {icacls $dir /inheritance:d}
                $resultsTextBox.AppendText("`r`n$confirmationResult")

                # Wywołaj komendę
                $commandToExecute = "Write-Host 'Komenda została wykonana'"
                Invoke-Expression -Command $commandToExecute
            }
        }
    })

    # Dodanie obsługi zdarzenia TextChanged dla pierwszego pola tekstowego
    $textBoxPath.Add_TextChanged({
        # Jeśli pierwsze pole tekstowe nie jest puste, aktywuj przycisk "Dziedziczenie"
        $buttonInheritance.Enabled = $textBoxPath.Text -ne ""
    })
    $mainForm.Controls.Add($buttonInheritance)



# Etykieta dla opisu "Lista dostępnych grup"
$labelAvailableGroups = New-Object System.Windows.Forms.Label
$labelAvailableGroups.Text = "Lista dostępnych grup:"
$labelAvailableGroups.Location = New-Object System.Drawing.Point(10, 210)
$labelAvailableGroups.Width = 150
$mainForm.Controls.Add($labelAvailableGroups)

# Etykieta dla opisu "Lista dostępnych grup"
$labelAvailableDirectories = New-Object System.Windows.Forms.Label
$labelAvailableDirectories.Text = "Lista podfolderów z folderu głównego:"
$labelAvailableDirectories.Location = New-Object System.Drawing.Point(230, 210)
$labelAvailableDirectories.Width = 200
$mainForm.Controls.Add($labelAvailableDirectories)

# Funkcja do aktualizacji listy dostępnych grup w folderze i jego podfolderach
function UpdateAvailableGroupsList {
    $directory = $textBoxPath.Text

    # Sprawdzenie, czy wprowadzony tekst jest poprawną ścieżką katalogu
    if (Test-Path $directory -PathType Container) {
        $directories = Get-ChildItem $directory -Recurse | ForEach-Object { (Get-Acl $_.FullName).Access | Where-Object { $_.IdentityReference -is [System.Security.Principal.NTAccount] } | Select-Object -ExpandProperty IdentityReference } | ForEach-Object { $_.ToString().ToLower() } | Select-Object -Unique

        # Dodawanie wyników bezpośrednio do pola tekstowego z nową linią po każdym wyniku
        $directories -split "`r`n" | ForEach-Object {
            $availableGroupsTextBox.AppendText("$_")
        }
    }
}
function UpdateAvailableDirectoriesList {
    $directory = $textBoxPath.Text

    # Sprawdzenie, czy wprowadzony tekst jest poprawną ścieżką katalogu
    if (Test-Path $directory -PathType Container) {
        $directories = (Get-ChildItem $directory -Directory).FullName + "`r`n"

        # Dodawanie wyników bezpośrednio do pola tekstowego z nową linią po każdym wyniku
        $directories -split "`r`n" | ForEach-Object {
            $availableDirectoriesTextBox.AppendText("$_")
        }
    }
}


    [System.Windows.Forms.Application]::Run($mainForm)
    
