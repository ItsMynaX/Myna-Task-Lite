# --- [ 1. QUYỀN ADMIN & ÉP LUỒNG STA (CHỐNG CRASH) ] ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ($Host.Runspace.ApartmentState -ne 'STA') {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File "$PSCommandPath"; return
}

try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
} catch { 
    [System.Windows.MessageBox]::Show("SYSTEM ERROR: Thiếu thư viện WPF!")
    exit 
}

# --- [ 2. NTDLL ENGINE (DYNAMIC CLASS CHỐNG XUNG ĐỘT) ] ---
# Tạo tên class ngẫu nhiên theo thời gian thực để không bị lỗi "Type already exists"
$ClassName = "OmniCore_" + (Get-Date).Ticks

$Win32Code = @"
    using System;
    using System.Runtime.InteropServices;
    public class $ClassName {
        [DllImport("ntdll.dll")] public static extern int NtSuspendProcess(IntPtr h);
        [DllImport("ntdll.dll")] public static extern int NtResumeProcess(IntPtr h);
    }
"@
try { Add-Type -TypeDefinition $Win32Code } catch { }

# --- [ 3. GIAO DIỆN XAML (UPDATE SCALE UI) ] ---
# Sử dụng Grid Column/Row definitions để UI tự động giãn nở khi Resize
$xamlText = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="MynaTask Lite [Scale Update]" MinWidth="700" MinHeight="450" Width="850" Height="550" 
        Background="#0A0A0A" WindowStartupLocation="CenterScreen">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <RowDefinition Height="*"/>    <RowDefinition Height="Auto"/> </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/> <ColumnDefinition Width="Auto"/> <ColumnDefinition Width="Auto"/> <ColumnDefinition Width="Auto"/> <ColumnDefinition Width="*"/>    <ColumnDefinition Width="Auto"/> </Grid.ColumnDefinitions>

            <TextBox Name="SearchBox" Grid.Column="0" Width="200" Height="28" Background="#111" Foreground="#0F8" BorderBrush="#333" VerticalContentAlignment="Center" Padding="8,0"/>
            <Button Name="BtnSuspend" Grid.Column="1" Content="SUSPEND" Width="80" Height="28" Margin="10,0,0,0" Background="#1A1A1A" Foreground="#FFA500" BorderBrush="#444"/>
            <Button Name="BtnResume" Grid.Column="2" Content="RESUME" Width="80" Height="28" Margin="8,0,0,0" Background="#1A1A1A" Foreground="#00CCFF" BorderBrush="#444"/>
            <Button Name="BtnKill" Grid.Column="3" Content="KILL" Width="80" Height="28" Margin="8,0,0,0" Background="#311" Foreground="#F44" BorderBrush="#F44"/>
            
            <StackPanel Grid.Column="5" Orientation="Horizontal" VerticalAlignment="Center">
                <CheckBox Name="ChkAuto" Content="Auto-Sync" IsChecked="True" Foreground="#888" VerticalAlignment="Center" Margin="0,0,15,0"/>
                <TextBlock Name="CPUTxt" Text="CPU: --%" Foreground="#0F8" FontWeight="Bold"/>
            </StackPanel>
        </Grid>

        <DataGrid Name="ProcGrid" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" 
                  Background="#050505" Foreground="#EEE" RowBackground="#0A0A0A" AlternatingRowBackground="#0E0E0E" 
                  SelectionMode="Single" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#151515"
                  HorizontalAlignment="Stretch" VerticalAlignment="Stretch">
            <DataGrid.Columns>
                <DataGridTextColumn Header=" PROCESS NAME" Binding="{Binding Name}" Width="250"/>
                <DataGridTextColumn Header=" PID" Binding="{Binding Id}" Width="80"/>
                <DataGridTextColumn Header=" RAM (MB)" Binding="{Binding RAM}" Width="100"/>
                <DataGridTextColumn Header=" EXEC PATH" Binding="{Binding Path}" Width="*"/> </DataGrid.Columns>
        </DataGrid>

        <Border Grid.Row="2" Background="#111" Margin="0,12,0,0" Padding="8" CornerRadius="3">
            <TextBlock Name="Status" Text="[SYSTEM] Engine Ready. Waiting for commands..." Foreground="#0F8" FontFamily="Consolas" FontSize="11"/>
        </Border>
    </Grid>
</Window>
"@

# --- [ 4. LOGIC XỬ LÝ (CORE MANAGER) ] ---
try {
    $xmlReader = [XML.XmlReader]::Create([System.IO.StringReader]$xamlText)
    $win = [Windows.Markup.XamlReader]::Load($xmlReader)
    
    # Mapping UI
    $SearchBox = $win.FindName("SearchBox")
    $ProcGrid  = $win.FindName("ProcGrid")
    $Status    = $win.FindName("Status")
    $CPUTxt    = $win.FindName("CPUTxt")
    $ChkAuto   = $win.FindName("ChkAuto")

    $ProcessList = New-Object System.Collections.ObjectModel.ObservableCollection[object]
    $ProcGrid.ItemsSource = $ProcessList

    $script:Updating = $false

    # Hàm cập nhật danh sách siêu tốc
    function Refresh-ProcessList {
        if ($script:Updating) { return }
        $script:Updating = $true

        $selectedId = if ($ProcGrid.SelectedItem) { $ProcGrid.SelectedItem.Id } else { $null }
        
        $current = Get-Process | Sort-Object WorkingSet64 -Descending
        $ProcessList.Clear()

        foreach ($p in $current) {
            $path = "System / Access Denied"
            try { $path = $p.Path } catch {}
            
            $ProcessList.Add([PSCustomObject]@{
                Id   = $p.Id
                Name = $p.ProcessName
                RAM  = [math]::Round($p.WorkingSet64 / 1MB, 1)
                Path = $path
            })
        }

        if ($selectedId) {
            $item = $ProcessList | Where-Object { $_.Id -eq $selectedId }
            if ($item) { $ProcGrid.SelectedItem = $item }
        }

        $script:Updating = $false
    }

    # Hàm thực thi lệnh an toàn (Tránh Crash khi lấy Handle)
    function Execute-Action($type) {
        $p = $ProcGrid.SelectedItem
        if (-not $p) { return }

        try {
            if ($type -eq "Kill") {
                Stop-Process -Id $p.Id -Force -ErrorAction Stop
                $Status.Text = "[X] TERMINATED: $($p.Name) (PID: $($p.Id))"
                Refresh-ProcessList
                return
            }

            # Lấy Handle an toàn
            $h = (Get-Process -Id $p.Id -ErrorAction Stop).Handle
            
            if ($type -eq "Suspend") {
                $null = (Invoke-Expression "[$ClassName]::NtSuspendProcess(`$h)")
                $Status.Text = "[-] SUSPENDED: $($p.Name) (PID: $($p.Id))"
            } elseif ($type -eq "Resume") {
                $null = (Invoke-Expression "[$ClassName]::NtResumeProcess(`$h)")
                $Status.Text = "[+] RESUMED: $($p.Name) (PID: $($p.Id))"
            }
        } catch {
            $Status.Text = "[!] ERROR: Access Denied to PID $($p.Id) (System Process?)"
        }
    }

    # Gán Event cho Nút bấm
    $win.FindName("BtnSuspend").Add_Click({ Execute-Action "Suspend" })
    $win.FindName("BtnResume").Add_Click({ Execute-Action "Resume" })
    $win.FindName("BtnKill").Add_Click({ Execute-Action "Kill" })

    # Xử lý Search Real-time
    $SearchBox.Add_TextChanged({
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($ProcessList)
        $txt = $SearchBox.Text.ToLower()
        $view.Filter = [Predicate[object]]{ param($item) $item.Name.ToLower().Contains($txt) }
    })

    # --- [ 5. HIỆU SUẤT & THREADING ] ---
    $cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(3)
    $timer.Add_Tick({ 
        try { 
            $val = [int]$cpuCounter.NextValue()
            $CPUTxt.Text = "CPU: $val%"
            
            if ($ChkAuto.IsChecked -and -not $SearchBox.IsFocused) { 
                Refresh-ProcessList 
            }
        } catch {} 
    })

    # Boot hệ thống
    Refresh-ProcessList
    $timer.Start()
    $win.ShowDialog() | Out-Null

} catch {
    # Nếu có lỗi, bung thông báo chi tiết thay vì tự tắt
    [System.Windows.MessageBox]::Show("CRASH LOG FATAL:`n" + $_.Exception.Message)
}