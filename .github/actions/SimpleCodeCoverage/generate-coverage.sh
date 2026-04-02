#!/bin/bash
set -e

# Get thresholds from environment variables
COV_GREEN=${COV_GREEN:-50}
COV_YELLOW=${COV_YELLOW:-20}
COMPLEX_GREEN=${COMPLEX_GREEN:-10}
COMPLEX_YELLOW=${COMPLEX_YELLOW:-20}
# CRAP band limits: class vs method (see action.yml inputs)
CRAP_CLASS_GREEN_MAX=${CRAP_CLASS_GREEN_MAX:-30}
CRAP_CLASS_YELLOW_MAX=${CRAP_CLASS_YELLOW_MAX:-60}
CRAP_METHOD_GREEN_MAX=${CRAP_METHOD_GREEN_MAX:-5}
CRAP_METHOD_YELLOW_MAX=${CRAP_METHOD_YELLOW_MAX:-12}
COVERAGE_FILE_PATTERN=${COVERAGE_FILE_PATTERN:-"TestResults/**/coverage.cobertura.xml"}

# Convert glob pattern to find-compatible pattern
# Replace ** with */ for recursive search
findPattern=$(echo "$COVERAGE_FILE_PATTERN" | sed 's|\*\*/|*/|g')

# Find coverage file using the pattern
coverageFile=$(find . -name "coverage.cobertura.xml" -path "*TestResults*" -type f | head -n 1)

echo "Looking for coverage files matching pattern: $COVERAGE_FILE_PATTERN"
echo "Found coverage file: $coverageFile"

if [ -n "$coverageFile" ] && [ -f "$coverageFile" ]; then
  lineRate=$(grep -oP 'line-rate="\K[^"]+' "$coverageFile" | head -n 1)
  branchRate=$(grep -oP 'branch-rate="\K[^"]+' "$coverageFile" | head -n 1)
  linePercent=$(awk "BEGIN {printf \"%.2f\", $lineRate * 100}")
  branchPercent=$(awk "BEGIN {printf \"%.2f\", $branchRate * 100}")
  
  echo "## Test Coverage Summary" >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "| Metric | Coverage |" >> $GITHUB_STEP_SUMMARY
  echo "|--------|----------|" >> $GITHUB_STEP_SUMMARY
  echo "| **Line Coverage** | **${linePercent}%** |" >> $GITHUB_STEP_SUMMARY
  echo "| **Branch Coverage** | **${branchPercent}%** |" >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  
  echo "### Coverage by Class" >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "| Class | File | Lines | Branches | Complexity | Hits | Line Cov | Branch Cov | [CRAP](https://testing.googleblog.com/2011/02/this-code-is-crap.html) |" >> $GITHUB_STEP_SUMMARY
  echo "|-------|------|-------|----------|------------|------|----------|------------|------|" >> $GITHUB_STEP_SUMMARY
  
  awk -v cov_green="$COV_GREEN" -v cov_yellow="$COV_YELLOW" -v comp_green="$COMPLEX_GREEN" -v comp_yellow="$COMPLEX_YELLOW" -v crap_green="$CRAP_CLASS_GREEN_MAX" -v crap_yellow="$CRAP_CLASS_YELLOW_MAX" '
  function color_text(text, color) {
    if (color == "red") return "🔴 " text
    if (color == "yellow") return "🟡 " text
    if (color == "green") return "🟢 " text
    return text
  }
  function get_cov_color(val) {
    if (val >= cov_green) return "green"
    if (val >= cov_yellow) return "yellow"
    return "red"
  }
  function get_complex_color(val) {
    if (val < comp_green) return "green"
    if (val < comp_yellow) return "yellow"
    return "red"
  }
  function worst_color(c1, c2, c3) {
    if (c1 == "red" || c2 == "red" || c3 == "red") return "red"
    if (c1 == "yellow" || c2 == "yellow" || c3 == "yellow") return "yellow"
    return "green"
  }
  # CRAP = complexity * (1 - line_coverage)^2  (line_coverage is Cobertura line-rate 0..1)
  function crap_score(comp, lineRate) {
    return (comp+0) * (1-lineRate) * (1-lineRate)
  }
  function get_crap_color(score) {
    if (score <= crap_green) return "green"
    if (score <= crap_yellow) return "yellow"
    return "red"
  }
  /<class / {
    match($0, /name="([^"]+)"/, name)
    match($0, /filename="([^"]+)"/, file)
    match($0, /line-rate="([^"]+)"/, lr)
    match($0, /branch-rate="([^"]+)"/, br)
    match($0, /complexity="([^"]+)"/, comp)
    lines=0
    branches=0
    totalHits=0
    getline
    while ($0 !~ /<\/class>/) {
      if ($0 ~ /<line /) {
        lines++
        match($0, /hits="([^"]+)"/, hits)
        totalHits += hits[1]
        if ($0 ~ /branch="True"/) branches++
      }
      getline
    }
    filename = file[1]
    sub(/.*TestTag\//, "", filename)
    
    lineCov = lr[1] * 100
    branchCov = br[1] * 100
    complexity = comp[1]
    
    lineColor = get_cov_color(lineCov)
    branchColor = get_cov_color(branchCov)
    complexColor = get_complex_color(complexity)
    nameColor = worst_color(lineColor, branchColor, complexColor)
    
    crapVal = crap_score(complexity, lr[1])
    crapColor = get_crap_color(crapVal)
    
    printf "| %s | %s | %d | %d | %s | %d | %s | %s | %s |\n", 
      color_text(name[1], nameColor), filename, lines, branches, 
      color_text(complexity, complexColor), totalHits,
      color_text(sprintf("%.2f%%", lineCov), lineColor),
      color_text(sprintf("%.2f%%", branchCov), branchColor),
      color_text(sprintf("%.2f", crapVal), crapColor)
  }' "$coverageFile" >> $GITHUB_STEP_SUMMARY
  
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "### Coverage by Method" >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "| Method | Lines | Branches | Complexity | Hits | Line Cov | Branch Cov | CRAP |" >> $GITHUB_STEP_SUMMARY
  echo "|--------|-------|----------|------------|------|----------|------------|------|" >> $GITHUB_STEP_SUMMARY
  
  awk -v cov_green="$COV_GREEN" -v cov_yellow="$COV_YELLOW" -v comp_green="$COMPLEX_GREEN" -v comp_yellow="$COMPLEX_YELLOW" -v crap_green="$CRAP_METHOD_GREEN_MAX" -v crap_yellow="$CRAP_METHOD_YELLOW_MAX" '
  function color_text(text, color) {
    if (color == "red") return "🔴 " text
    if (color == "yellow") return "🟡 " text
    if (color == "green") return "🟢 " text
    return text
  }
  function get_cov_color(val) {
    if (val >= cov_green) return "green"
    if (val >= cov_yellow) return "yellow"
    return "red"
  }
  function get_complex_color(val) {
    if (val < comp_green) return "green"
    if (val < comp_yellow) return "yellow"
    return "red"
  }
  function worst_color(c1, c2, c3) {
    if (c1 == "red" || c2 == "red" || c3 == "red") return "red"
    if (c1 == "yellow" || c2 == "yellow" || c3 == "yellow") return "yellow"
    return "green"
  }
  # CRAP = complexity * (1 - line_coverage)^2  (line_coverage is Cobertura line-rate 0..1)
  function crap_score(comp, lineRate) {
    return (comp+0) * (1-lineRate) * (1-lineRate)
  }
  function get_crap_color(score) {
    if (score <= crap_green) return "green"
    if (score <= crap_yellow) return "yellow"
    return "red"
  }
  /<class / {
    match($0, /name="([^"]+)"/, className)
    currentClass = className[1]
  }
  /<method / {
    match($0, /name="([^"]+)"/, name)
    match($0, /line-rate="([^"]+)"/, lr)
    match($0, /branch-rate="([^"]+)"/, br)
    match($0, /complexity="([^"]+)"/, comp)
    lines=0
    branches=0
    totalHits=0
    getline
    while ($0 !~ /<\/method>/) {
      if ($0 ~ /<line /) {
        lines++
        match($0, /hits="([^"]+)"/, hits)
        totalHits += hits[1]
        if ($0 ~ /branch="True"/) branches++
      }
      getline
    }
    
    lineCov = lr[1] * 100
    branchCov = br[1] * 100
    complexity = comp[1]
    
    lineColor = get_cov_color(lineCov)
    branchColor = get_cov_color(branchCov)
    complexColor = get_complex_color(complexity)
    nameColor = worst_color(lineColor, branchColor, complexColor)
    
    methodFullName = currentClass "." name[1]
    
    crapVal = crap_score(complexity, lr[1])
    crapColor = get_crap_color(crapVal)
    
    printf "| %s | %d | %d | %s | %d | %s | %s | %s |\n", 
      color_text(methodFullName, nameColor), lines, branches,
      color_text(complexity, complexColor), totalHits,
      color_text(sprintf("%.2f%%", lineCov), lineColor),
      color_text(sprintf("%.2f%%", branchCov), branchColor),
      color_text(sprintf("%.2f", crapVal), crapColor)
  }' "$coverageFile" >> $GITHUB_STEP_SUMMARY
else
  echo "## Test Coverage Summary" >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "⚠️ No coverage file found matching pattern: \`$COVERAGE_FILE_PATTERN\`" >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "Searched in:" >> $GITHUB_STEP_SUMMARY
  find . -name "*.xml" -path "*TestResults*" -type f >> $GITHUB_STEP_SUMMARY || echo "No XML files found in TestResults" >> $GITHUB_STEP_SUMMARY
fi
