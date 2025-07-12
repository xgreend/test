# Tạo restore point trước khi chạy
Checkpoint-Computer -Description "Before_Display_Reset" -RestorePointType "MODIFY_SETTINGS"

# 1. Gỡ driver GPU để Windows cài lại mặc định
Write-Host "Đang gỡ driver GPU tạm thời..."
Get-PnpDevice -Class Display | Disable-PnpDevice -Confirm:$false
Start-Sleep -Seconds 2
Get-PnpDevice -Class Display | Enable-PnpDevice -Confirm:$false

# 2. Xoá các registry lưu cấu hình màn hình hiển thị
$regPaths = @(
  "HKCU:\Control Panel\Desktop",
  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System",
  "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration",
  "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Connectivity",
  "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\ScaleFactors"
)

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Đã xoá: $path"
    }
}

# 3. Đặt lại độ sáng (nếu có thể)
Write-Host "Đặt lại độ sáng về 50%..."
try {
    (Get-WmiObject -Namespace root/wmi -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1,50)
} catch {
    Write-Host "Không thể điều chỉnh độ sáng (thiếu quyền hoặc không hỗ trợ)"
}

# 4. Reset nhanh GPU (tương đương Ctrl + Win + Shift + B)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class GPUReset {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
}
"@
[GPUReset]::keybd_event(0x5B, 0, 0, 0)     # Win
[GPUReset]::keybd_event(0x11, 0, 0, 0)     # Ctrl
[GPUReset]::keybd_event(0x10, 0, 0, 0)     # Shift
[GPUReset]::keybd_event(0x42, 0, 0, 0)     # B
Start-Sleep -Milliseconds 100
[GPUReset]::keybd_event(0x5B, 0, 2, 0)
[GPUReset]::keybd_event(0x11, 0, 2, 0)
[GPUReset]::keybd_event(0x10, 0, 2, 0)
[GPUReset]::keybd_event(0x42, 0, 2, 0)

# 5. Thông báo hoàn tất
Write-Host "`n✅ Đã làm sạch cài đặt màn hình. Vui lòng khởi động lại máy để áp dụng."
