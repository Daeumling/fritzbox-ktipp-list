<#
.SYNOPSIS
  Name: export-callcenterKTIPPFritzBox.ps1
  Script to Import KTIPP Blacklist and export it to separated fritzbox xml files (can be directly imported in phonebooks)
  
.DESCRIPTION
  The script will download the latest_cc_blacklist.txt by trick77 and compute its content.
  See https://raw.githubusercontent.com/trick77/callcenter-blacklist-switzerland/master/latest_cc_blacklist.tx.
  Output generated are FritzBox phonebook xml files ready for import to Fritzbox and google csv files read for import to google contacts.
  Each phonebook is containing a max of 500 contact entries.
  Fritzbox is supporting 500 contacts when using firtzbox phonebook, 1000 when using google adressbok.
  A contact name may have around 20 charcters in FritzBox, otherwise it will not be imported.
  Doublettes are identified and not imported, so content of each file may vary.
  A big thank to trick77 (https://github.com/trick77/callcenter-blacklist-switzerland).

.NOTES
  Author: Olav Daeumling
  V1.0 - 2019-08-23
#>


# if necessary: Set-ExecutionPolicy Unrestricted -Scope CurrentUser
$ErrorActionPreference = "SilentlyContinue"


function Insert-Content {
    param ( [String]$Path )

    process {
        $( ,$_; Get-Content $Path -ea SilentlyContinue) | Out-File $Path
    }
}

# define variables
$entrycounter = 1
$counter = 0
$googlecounter = 0
$googlefilecounter = 1
$filecounter = 1
$url = "https://raw.githubusercontent.com/trick77/callcenter-blacklist-switzerland/master/latest_cc_blacklist.txt"

# define file paths and file names; $path will define the basic path (change to whatever you like - directory must by writable by script!)
# filenames will begin with timestamp of script execution to divert from older files
$path = "C:\temp"
$output = "$path\$tstamp-cc_blacklist.txt"
$file = "$path\$tstamp-latest_cc_blacklist_computed.csv"
$tstamp = $(get-date -f MM-dd-yyyy_HH_mm_ss)

# do not change the $text lines!
$text = '<?xml version="1.0" encoding="utf-8"?>
<phonebooks>
<phonebook>'

# get file latest_cc_blacklist.txt
Invoke-WebRequest -Uri $url -OutFile $output

# import file, ignore all lines bginning with "#"
$datafile = Get-Content $output |
    Where-Object { !$_.StartsWith("#") } 

write-host "converting..."

# define data storing variables
$dataset = @{number= "";lastname= ""}
$dataset_google = "Name,Given Name,Additional Name,Family Name,Yomi Name,Given Name Yomi,Additional Name Yomi,Family Name Yomi,Name Prefix,Name Suffix,Initials,Nickname,Short Name,Maiden Name,Birthday,Gender,Location,Billing Information,Directory Server,Mileage,Occupation,Hobby,Sensitivity,Priority,Subject,Notes,Language,Photo,Group Membership,E-mail 1 - Type,E-mail 1 - Value,E-mail 2 - Type,E-mail 2 - Value,Phone 1 - Type,Phone 1 - Value,Phone 2 - Type,Phone 2 - Value,Phone 3 - Type,Phone 3 - Value,Address 1 - Type,Address 1 - Formatted,Address 1 - Street,Address 1 - City,Address 1 - PO Box,Address 1 - Region,Address 1 - Postal Code,Address 1 - Country,Address 1 - Extended Address,Organization 1 - Type,Organization 1 - Name,Organization 1 - Yomi Name,Organization 1 - Title,Organization 1 - Department,Organization 1 - Symbol,Organization 1 - Location,Organization 1 - Job Description
"

# convert for fritzbox import
ForEach ($data in $datafile) {

    $counter++
    $googlecounter++

    $number = $data.split(";")[0]
    if ($number.SubString(0,2) -ne "00") {
        $number = "0041" + $number.SubString(1,$number.Length-1)
    }
    
    $company = $data.split(";")[1]

    # Clean text 
    $company = $company -replace "Firma Firma", "Firma"
    $company = $company -replace "Firma Callcenter", "Callcenter"
    $company = $company -replace "Callcenter unbekannt", "Callcenter"
    $company = $company -replace "Firma unbekannt", "Firma"
    $company = $company -replace "Bemerkung.*", ""
    # shorten company entry to 20 chars (otherwise import problems for fritzbox xml import)
    $company = $company.Substring(0,20)
    # clean empty company data
    if ($company -eq "") {$company = "Firma"}

    # Add data
    try {
        $company_computed = "$entrycounter $company"
        $dataset.add($number,$company_computed)
        
        if ($counter -le 501) {

            $entrycounter++

# do not change the $text lines!
$text += '<contact>
<category>0</category>
<person>
<realName>'+$entrycounter+' '+$company+'</realName>
</person>
<telephony>
<number type="home" prio="1">'+$number+'</number><number
type="work" id="1" /><number type="mobile" id="2" /></telephony><services
nid="1"><email id="0" /></services><setup><ringTone /><ringVolume /></setup><uniqueid>'+$entrycounter+'</uniqueid></contact>'

        }
        else {
            # write out fritz phonebook, start new one
            # a fritzbox phone book can contain max 500 entries !

# do not change the $text lines!  
$text += '</phonebook>
</phonebooks>'
   
            $xml = "$tstamp-FritzBox_Callblocker_Book_$filecounter.xml"
            $file2 = "$path\$tstamp-FritzBox_Callblocker_Book_$filecounter.xml"

            if (!(Get-item $xml)) {
                New-Item -path $path -name $xml -ItemType "file" -Force
            }   
            $text | Out-File $file2 -Encoding utf8

# do not change the $text lines!
$text = '<?xml version="1.0" encoding="utf-8"?>
<phonebooks>
<phonebook>'

            # compute counters
            $counter = 1
            $filecounter++
        }

        if ($googlecounter -le 501)   {
            # process google adressbook csv (max 500 entries)
            # fritzbox can handle max 1000 entries per book from google or other online account, but this caused problems, so only 500 entries
            # google itself can import max 5000 entries at once; max 25000 entries at all
            $dataset_google += "$entrycounter $company,,,$entrycounter $company,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,Work,$number,,,,,,,,,,,,,,,,,,,`n"
        }  
        else {
            # write out google adresbook, create new one
            $filegoogle = "$path\$tstamp-google-import_$googlefilecounter.csv"
            $dataset_google | Out-File $filegoogle -Encoding utf8
            $dataset_google = "Name,Given Name,Additional Name,Family Name,Yomi Name,Given Name Yomi,Additional Name Yomi,Family Name Yomi,Name Prefix,Name Suffix,Initials,Nickname,Short Name,Maiden Name,Birthday,Gender,Location,Billing Information,Directory Server,Mileage,Occupation,Hobby,Sensitivity,Priority,Subject,Notes,Language,Photo,Group Membership,E-mail 1 - Type,E-mail 1 - Value,E-mail 2 - Type,E-mail 2 - Value,Phone 1 - Type,Phone 1 - Value,Phone 2 - Type,Phone 2 - Value,Phone 3 - Type,Phone 3 - Value,Address 1 - Type,Address 1 - Formatted,Address 1 - Street,Address 1 - City,Address 1 - PO Box,Address 1 - Region,Address 1 - Postal Code,Address 1 - Country,Address 1 - Extended Address,Organization 1 - Type,Organization 1 - Name,Organization 1 - Yomi Name,Organization 1 - Title,Organization 1 - Department,Organization 1 - Symbol,Organization 1 - Location,Organization 1 - Job Description
"
            # compute counters
            $googlecounter = 1
            $googlefilecounter++
        }
    
    }
    catch {
        write-host "Double Dataset $number $company not added" -ForegroundColor Yellow
    }

}

write-host "Exporting csv ..."

# Export new file
if (Test-Path $file) {Remove-Item $file}
$dataset.GetEnumerator() |
    foreach {new-object -typename psobject -property @{number = $_.name; description = $_.value}} | 
    Export-csv $file -Delimiter "," -NoTypeInformation

# Remove first line of file
# (Get-Content $file | Select-Object -Skip 1) | Set-Content $file

write-host "DONE."
