<#
.Synopsis
   Update html files with hosted libraries and add the desired CreateJS library to the html and folder.
.DESCRIPTION
   Will search all Adobe Animate published HTML5 CreateJS animations for hosted CreateJS libraries. 
   If found, it will correct the html and add the supplied CreateJS library to the /libs folder in each animation folder. 
   If you do not provide a path, the current folder will be processed. The script assumes that there is one CreateJS animation per folder.
.PARAMETER Path
   Specifies the path to the folder containing the animations to be updated.
.PARAMETER cjsPath
   Specifies the path to the local CreateJS library. Must be a .js file. 
.PARAMETER recurse
   Indicates that this cmdlet will update the items in the specified path and in all child items of the path.
.PARAMETER zip
   Compresses the contents of the folder into a zip file package that can be imported to Adobe Captivate. 
   This parameter has no effect if there are no changes needed for the animation.  
.EXAMPLE
   Update-CjsLibrary -Path c:\animations -cjsPath c:\scripts\createjs-2015.11.26.min.js -recurse -zip
   
   Checks html file headers in c:\animations and all subfolders for links to hosted CreateJS libraries. 
   If found, the link is replaced with the local copy specified in -cjsPath and the referenced .js file is then added to the libs folder. 
   Since the -zip flag is included, the folders will be compressed into a file with the same name as the modified html file. 
.EXAMPLE
   Update-CjsLibrary -cjsPath c:\scripts\createjs-2015.11.26.min.js 

   Checks html file headers in the current folder for links to hosted CreateJS libraries. 
   If found, the link is replaced with the local copy specified in -cjsPath and the referenced .js file is then added to the libs folder. 
.EXAMPLE
    Get-ChildItem C:\animations | ForEach{Update-CjsLibrary $_.Fullname -cjsPath C:\scripts\createjs-2015.11.26.min.js -recurse -zip}

    Accepts the pipeline ouput of a command like Get-ChildItem, and replaces the link in the HTML, adds the .js file for each item and subfolders. 
    Each folder's contents are then zipped into a package. 
#>
function Update-CjsLibrary
{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # -Path set the path of the target folder to update, or a parent folder to update multiple animations, with -recurse
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({
           if(-Not ($_ | Test-Path) ) {
               throw "File or folder does not exist."
           }
           if(-Not ($_ | Test-Path -PathType Container) ){
               throw "The Path argument must be a folder. Files are not allowed."
           }
         return $true
        })]
        [System.IO.FileInfo]$Path,

        # -cjsPath is the path to the CreateJS .js file that will be included in the animation folder and .html files
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ) {
               throw "File or folder does not exist."
            }
           if(-Not ($_ | Test-Path -PathType Leaf) ){
               throw "The cjsPath argument must point to a file. Folder paths are not allowed."
            }
            if($_ -notmatch "\.js" ){
               throw "The file specified in the path argument must be a JavaScript file."
            }
         return $true
        })]
        [System.IO.FileInfo]$cjsPath,

        # If -recurse is present, subfolders will be searched for CreateJS hosted libraries
        [Parameter()]
        [switch]$recurse = $false,

        # If -zip is present, a zip file will be created containing animation assets in each folder IF there was a change made
        [Parameter()]
        [switch]$zip = $false
    )

    begin {
        if(-Not $Path){
            $Path = ".\"
         }
         $cjsFileName = Split-Path $cjsPath -Resolve -Leaf
         $cjsReplaceString = "<script type='text/javascript' src='libs/" + $cjsFileName + "'></script>"
    }
    
    process {
        if($recurse) {
            $fileList = Get-ChildItem $Path *.html -Recurse | ForEach-Object {$_.Fullname}
         } else {
            $fileList = Get-ChildItem $Path *.html | ForEach-Object {$_.Fullname}
         }
         
         if (0 -eq $fileList.Length){
            Write-host("No HTML files found.")
            Break
         }    

        forEach ($updateFile in $fileList) {
            $oldHTML = get-content $updateFile -Encoding UTF8
            $newHtml = ""
            $changes = 0
            $i = 0
        
            while ($i -lt $oldHTML.length) {
                $oldHtmlText = [string]$oldHTML[$i]
                $tempLine = $oldHtmlText     
                $tempLine = $tempLine -Replace '<script src="https:\/\/code\.createjs\.com\/.*$', $cjsReplaceString
                if ($tempLine -ne $oldHTMLText) {
                    $changes++
                }
                $tempLine += "`n"
                $newHtml += $tempLine
                $i++
            }
    
            if ($changes -ne 0) { 
                $newHtml | Out-File $updateFile -Encoding UTF8
                $libPath = Split-Path $updateFile
                $zipFile = (Get-Item $updateFile).Basename
                    
                    Copy-Item  $cjsPath $libPath\libs\
                    
                    if($PSCmdlet.ShouldProcess){ 
                    Write-host $updateFile "updated. There were" $changes "change(s) made." -ForegroundColor Green
                    }
                    
                    if ($zip){
                        if($PSCmdlet.ShouldProcess($zipFile, "Compress-Archive")){ 
                            $filesToZip = Get-ChildItem $libPath | Where-Object { $_.Name -like "images" -or $_.Name -like "libs" -or $_.Name -like "sounds" -or $_.Name -like "*.html" -or $_.Name -like "*.jpg" -or $_.Name -like "*.js" }                  
                            $zipFileFullPath = @()
                
                            ForEach ($fileToZip in $filesToZip) {
                                $zipFileFullPath += $fileToZip.FullName
                            }
                                        
                            Compress-Archive -Path $zipFileFullPath -DestinationPath $libPath\$zipFile -Force
                        }
                    }
            }
    
            if ($changes -eq 0) {
                Write-host $updateFile "was not updated. No changes were needed."  
            }
        }
    }
    
    end {
        Remove-Variable oldHtml
        Remove-Variable newHtml
    }
}

