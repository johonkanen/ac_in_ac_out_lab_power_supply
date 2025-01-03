# Check if the current directory is a Git repository
if (-not (git rev-parse --is-inside-work-tree -q)) {
    Write-Host "This directory is not a Git repository."
    exit
}

# Get the short Git hash of the current HEAD
$gitHash = git rev-parse --short HEAD

# Ensure the hash is exactly 8 hex digits by padding with leading zeros if necessary
$gitHashPadded = $gitHash.PadLeft(8, '0')

# Define the output file name
$outputFile = "git_hash_pkg.vhd"

# Create the VHDL file content
$vhdlContent = @"
library ieee;
    use ieee.std_logic_1164.all;

package git_hash_pkg is

    constant git_hash : std_logic_vector(31 downto 0) := x"$gitHashPadded";
end package;
"@

# Write the content to the output file
$vhdlContent | Out-File -FilePath $outputFile -Encoding utf8

Write-Host "The Git hash has been written to $outputFile"

