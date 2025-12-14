# ====================================================
# Full system check script with separate battery report
# ====================================================

# -----------------------------
# File paths
# -----------------------------
$systemReport = "C:\pc_full_report.txt"
$batteryReport = "C:\battery_report.html"

# Remove old reports if exist
if (Test-Path $systemReport) { Remove-Item $systemReport }
if (Test-Path $batteryReport) { Remove-Item $batteryReport }

# Helper function to write section headers
function Write-SectionHeader($title) {
    Add-Content $systemReport ("`n" + "=" * 60)
    Add-Content $systemReport ("= " + $title)
    Add-Content $systemReport ("=" * 60 + "`n")
}

# -----------------------------
# 1. Basic System Info
# -----------------------------
Write-Output "Collecting basic system info..."
Write-SectionHeader "BASIC SYSTEM INFO (CPU, RAM, GPU, DISK)"

# CPU
Add-Content $systemReport "CPU:"
Get-CimInstance -ClassName Win32_Processor | Select Name, NumberOfCores, MaxClockSpeed | Format-Table | Out-String | Add-Content $systemReport

# RAM
Add-Content $systemReport "`nRAM:"
Get-CimInstance -ClassName Win32_PhysicalMemory | Select Manufacturer, Capacity, Speed | Format-Table | Out-String | Add-Content $systemReport

# GPU
Add-Content $systemReport "`nGPU:"
Get-CimInstance -ClassName Win32_VideoController | Select Name, DriverVersion | Format-Table | Out-String | Add-Content $systemReport

# Disk
Add-Content $systemReport "`nDISK:"
Get-CimInstance -ClassName Win32_DiskDrive | Select Model, InterfaceType, MediaType, Size | Format-Table | Out-String | Add-Content $systemReport

# -----------------------------
# 2. Disk SMART Status
# -----------------------------
Write-Output "Collecting SMART disk status..."
Write-SectionHeader "DISK SMART STATUS"
try {
    Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus | Select InstanceName, PredictFailure | Format-Table | Out-String | Add-Content $systemReport
} catch {
    Add-Content $systemReport "Failed to collect SMART info. Possibly insufficient permissions. ${_}"
}

# -----------------------------
# 3. Last 20 critical system errors
# -----------------------------
Write-Output "Collecting last 20 critical system errors..."
Write-SectionHeader "LAST 20 CRITICAL SYSTEM ERRORS"
try {
    wevtutil qe System /q:"*[System[(Level=2)]]" /c:20 /f:text | Out-String | Add-Content $systemReport
} catch {
    Add-Content $systemReport "Failed to collect system errors. ${_}"
}

# -----------------------------
# 4. Battery Report (separate file)
# -----------------------------
Write-Output "Generating battery report (requires admin)..."
try {
    powercfg /batteryreport /output $batteryReport
    Write-Output "Battery report saved to $batteryReport"
} catch {
    Write-Output "Failed to generate battery report. Run PowerShell as administrator. ${_}"
}

# -----------------------------
# 5. ChatGPT prompt for system analysis
# -----------------------------
Write-SectionHeader "PROMPT FOR CHATGPT"
$chatPrompt = @"
Привіт, ChatGPT! Ось файл з повною інформацією про комп'ютер. Наступним повідомленням буде надіслано файл батареї окремо. 
Будь ласка, простими словами і людською мовою опиши стан ноутбука, оцінюючи знос основних компонентів (CPU, RAM, GPU, диск) у відсотках, можливі проблеми та приблизну тривалість служби. 
Також врахуй історію помилок та SMART-статус диска.
"@
Add-Content $systemReport $chatPrompt

# -----------------------------
Write-Output "`nSystem check completed. Reports saved:"
Write-Output "1. System info: $systemReport"
Write-Output "2. Battery report: $batteryReport"
