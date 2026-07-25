# ============================================================
# RLS Security Regression Check
# ============================================================
# Scans SQL files for unsafe RLS policy patterns.
# Fails if any insecure patterns are found.
# ============================================================

param(
    [string]$SearchPath = "."
)

$exitCode = 0
$unsafePatterns = @(
    @{ Pattern = 'OR true'; Description = 'OR true bypass in policy' }
    @{ Pattern = 'WITH CHECK\s*\(\s*true\s*\)'; Description = 'Unrestricted WITH CHECK (true)' }
    @{ Pattern = 'FOR ALL USING\s*\(\s*true\s*\)'; Description = 'Unrestricted FOR ALL' }
)

Write-Host "=== RLS Security Regression Check ===" -ForegroundColor Cyan
Write-Host "Scanning SQL files in: $SearchPath`n" -ForegroundColor Cyan

$sqlFiles = Get-ChildItem -Path $SearchPath -Recurse -Filter "*.sql" | Where-Object { $_.FullName -notlike "*build*" -and $_.FullName -notlike "*\.dart_tool*" -and $_.FullName -notlike "*node_modules*" }

if ($sqlFiles.Count -eq 0) {
    Write-Host "No SQL files found." -ForegroundColor Yellow
    exit 0
}

foreach ($file in $sqlFiles) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
    $content = Get-Content -Path $file.FullName -Raw
    
    foreach ($pattern in $unsafePatterns) {
        $matches = [regex]::Matches($content, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        foreach ($match in $matches) {
            # Calculate line number
            $lineNum = ($content.Substring(0, $match.Index).Split("`n").Length)
            
            $lineContent = ($content.Split("`n")[$lineNum - 1]).Trim()
            
            # Skip SQL comments and doc lines
            if ($lineContent -match '^--') { continue }
            
            # Skip false positives: harmless SELECT USING (true)
            if ($lineContent -match "FOR SELECT USING\s*\(\s*true\s*\)" -and $pattern.Pattern -eq 'OR true') {
                continue
            }
            if ($lineContent -match "FOR SELECT USING\s*\(\s*true\s*\)" -and $pattern.Pattern -eq 'FOR ALL USING\s*\(\s*true\s*\)') {
                continue
            }
            if ($lineContent -match "Anyone can read" -and $pattern.Pattern -eq 'WITH CHECK\s*\(\s*true\s*\)') {
                continue
            }
            
            Write-Host "FAIL: $relativePath($lineNum) - $($pattern.Description)" -ForegroundColor Red
            Write-Host "       $($lineContent.Trim())" -ForegroundColor DarkRed
            $exitCode = 1
        }
    }
}

if ($exitCode -eq 0) {
    Write-Host "`nPASS: No unsafe RLS patterns found." -ForegroundColor Green
} else {
    Write-Host "`nFAILURE: Unsafe RLS patterns detected. Fix before deployment." -ForegroundColor Red
}

exit $exitCode
