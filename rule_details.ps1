$observed_rule_ids = @("77d86c5f-205c-47ec-98e3-0612e90b6980","ee71d10b-9405-403e-9057-9e2b2287a554","9e400deb-ac14-48b1-889f-9a1f77685118","f0c33ee3-2a80-4404-a6d3-3ac8525351ae","98101730-c7f2-443a-aa37-92ba20eb297e","796198f4-aaf5-4d12-a11a-69764a45c491","12dea31d-feff-4810-9b40-6ccddf7566dd", "5f802052-c438-4b5a-9f83-aedfe5bcb7de")


For ($i=0; $i -lt $observed_rule_ids.Length; $i++) {
    If ($i -eq 0) {
        Get-TransportRule -Identity $observed_rule_ids[$i] |Export-Csv -Path .\observed_transport_rules.csv
    } Else {
        Get-TransportRule -Identity $observed_rule_ids[$i] |Export-Csv -Path .\observed_transport_rules.csv -IncludeTypeInformation -Append
    }
}