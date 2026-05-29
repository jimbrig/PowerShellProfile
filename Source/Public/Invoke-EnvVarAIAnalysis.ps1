# $Prompt = @"
# Provide a comprehensive analysis of the following Windows environment variables:
# 1. PATH analysis:
#    - Identify and recommend removal of duplicate entries
#    - Flag non-existent directories
#    - Suggest ordering improvements
#    - Identify missing important directories

# 2. Security review:
#    - Identify potential credential information
#    - Flag overly permissive paths
#    - Recommend least privilege adjustments

# 3. System configuration assessment:
#    - Identify misconfigurations or unusual settings
#    - Provide optimization suggestions
#    - Highlight conflicting variables

# 4. Best practices:
#    - Recommend organization improvements
#    - Suggest user vs system variable distribution
#    - Identify obsolete or deprecated paths

# Variables:
# {0}
# "@

# $EnvVars = Get-EnvironmentVariables -AnalyzePath -OutputFormat List | Out-String
# $EnvVarAIAnalysis = Invoke-AIPrompt -Prompt $Prompt -Model 'gpt-4o' -Data @{
#     EnvVars = $EnvVars
# } -MaxTokens 4000 -Temperature 0.7

