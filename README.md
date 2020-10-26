# update-cjslibrary
Powershell module to update HTML files with hosted CreateJS libraries and add the library to the folder.

## Description
Will search all Adobe Animate published HTML5 CreateJS animations for hosted CreateJS libraries. 
If found, it will correct the html and add the supplied CreateJS library to the /libs folder in each animation folder. 
If you do not provide a path, the current folder will be processed. The script assumes that there is one CreateJS animation per folder.

This cmdlet supports -WhatIf and the pipeline.

Add to PowerShell using Import-Module. 

---
### Example 1
Update-CjsLibrary -Path c:\animations -cjsPath c:\scripts\createjs-2015.11.26.min.js -recurse -zip

Checks html file headers in c:\animations and all subfolders for links to hosted CreateJS libraries. If found, the link is replaced with the local copy specified in -cjsPath and the referenced .js file is then added to the libs folder. Since the -zip flag is included, the folders will be compressed into a zip file with the same name as the modified html file. 

### Example 2
Get-ChildItem C:\animations | ForEach{Update-CjsLibrary $_.Fullname -cjsPath C:\scripts\createjs-2015.11.26.min.js -recurse -zip}

Accepts the pipeline output of a command like Get-ChildItem, recursively searches the path and subfolders, replaces the link in the HTML and adds the .js file for each html file if needed. Each folder's contents are then zipped if the HTML file was modified. 
