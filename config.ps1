& ".\pc-check.ps1"

$CONFIG_TEXT = Get-Content "pc_full_report.txt" -Raw

$OPENROUTER_API_KEY = Get-Content ".\apikey.txt" -Raw

$body = @{
    model = "openai/gpt-4o-mini"
    messages = @(
        @{
            role = "user"
            content = "Here are my pc config: $CONFIG_TEXT Write me a report."
        }
    )
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod `
    -Uri "https://openrouter.ai/api/v1/chat/completions" `
    -Method Post `
    -Headers @{
        "Content-Type"  = "application/json; charset=utf-8"
        "Authorization" = "Bearer $OPENROUTER_API_KEY"
    } `
    -Body $body

$response.choices[0].message.content