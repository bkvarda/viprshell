###ViPRshell###
#ViPR PowerShell Module#
#Created by Brandon Kvarda#

#Trust all certificates
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

####Token Generation####

#Creates the proxy token - this will be a one-time setup typically
Function New-ViPR-Proxy-Token{
[Cmdletbinding()]

Param(
  [string]$ViprIP,
  [string]$Username,
  [string]$Password,
  [string]$Proxyusername,
  [string]$Proxypassword,
  [string]$TokenPath
)

    #If the path doesn't exist, create it
    $result = Test-Path $TokenPath
    if(!$result){

       $created = New-Item $TokenPath -ItemType directory

    }

    $initialloginuri = "https://"+$ViprIP+":4443/login"

    #creating base64 basic authentication header using helper function for initial login
    $headers = Get-AuthHeader -username $Username -password $Password

    #send the initial login request 
    $response = (Invoke-WebRequest -Uri $initialloginuri -Method GET -Headers $headers -ContentType "application/json")
    $authtoken = $response.Headers.'X-SDS-AUTH-TOKEN'
    $headers.add("X-SDS-AUTH-TOKEN",$authtoken)


    $tokenuri = "https://"+$ViprIP+":4443/proxytoken"

    #Now send the request to obtain the proxy token for your user
    $request = Invoke-WebRequest -Uri $tokenuri -WebSession $session -Method GET -ContentType "application/json" -Headers $headers
    $request.Headers.'X-SDS-AUTH-PROXY-TOKEN' | Out-File "$TokenPath/viprproxytoken.txt" -Force


}
#Authenticates the proxy user using the proxy token that was already created
Function New-ViprProxyUserAuthToken{
 [Cmdletbinding()]
 Param(
 [Parameter(Mandatory=$true)]
 [string]$ViprIP,
 [Parameter(Mandatory=$true)]
 [string]$TokenPath,
 [Parameter(Mandatory=$true)]
 [string]$ProxyUserName,
 [Parameter(Mandatory=$true)]
 [string]$ProxyUserPassword
 )  

    #If the path doesn't exist, create it
    $result = Test-Path $TokenPath
    if(!$result){

       $created = New-Item $TokenPath -ItemType directory

    }

    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $newheaders = Get-AuthHeader -username $ProxyUserName -password $ProxyUserPassword
    $newheaders.add("X-SDS-AUTH-PROXY-TOKEN",$proxytoken)

    $loginuri = "https://"+$ViprIP+":4443/login"

    #Now get the auth token and proxy token for the proxyuser
    $tokenrequest = Invoke-WebRequest -Uri $loginuri -Method Get -Headers $newheaders -ContentType "application/json"
    $tokenrequest.Headers.'X-SDS-AUTH-TOKEN' | Out-File "$TokenPath/viprauthtoken.txt" -Force

   


}


####Tenant Services####
Function Get-ViPRTenant{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

    $uri = "https://"+$ViprIP+":4443/tenants/search?name=$Name"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    
    $result = try{ 
    
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
        
                    $id = ($response.resource | Where match -eq $Name | Select).id

                     #Uses bogus ID if no match was found to trigger error
                    if(!$id){
                    $id = "$Name"
                    }
                    
                    $uri = "https://"+$ViprIP+":4443/tenants/$id"

                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                }
            catch{

                Get-ViPRErrorMsg -errordata $result
            }

    $result
}

Function Get-ViPRProject{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

    $uri = "https://"+$ViprIP+":4443/projects/search?name=$Name"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    $result = try{ 
    
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
        
                    $id = ($response.resource | Where match -eq $Name | Select).id

                     #Uses bogus ID if no match was found to trigger error
                    if(!$id){
                    $id = "$Name"
                    }
                    
                    $uri = "https://"+$ViprIP+":4443/projects/$id"

                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                }
            catch{

                Get-ViPRErrorMsg -errordata $result
            }

         $result

 
}


####Compute Services####
Function Get-ViPRHost{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [ValidateSet('Cluster','Standalone')]
  [string]$HostType
)
    if($HostType -eq 'Standalone'){
    $uri = "https://"+$ViprIP+":4443/compute/hosts/search?name=$Name"
    }
    else{
    $uri = "https://"+$ViprIP+":4443/compute/clusters/search?name=$Name"
    }


        $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
        $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
        $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
        
    $result = try{ 
    
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
        
                    $id = ($response.resource | Where match -eq $Name | Select).id

                     #Uses bogus ID if no match was found to trigger error
                    if(!$id){
                    $id = "$Name"
                    }
                    
                    if($HostType -eq 'Standalone'){
                    $uri = "https://"+$ViprIP+":4443/compute/hosts/$id"
                    }
                    else{
                    $uri = "https://"+$ViprIP+":4443/compute/clusters/$id"
                    }
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                }
            catch{

                Get-ViPRErrorMsg -errordata $result
            }

         $result
 
}


Function Get-ViprExportGroup{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

    $uri = "https://"+$ViprIP+":4443/block/exports/search?name=$Name"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    $result = try{ 
    
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
                    Write-Host $response
                    $id = ($response.resource).id

                     #Uses bogus ID if no match was found to trigger error
                    if(!$id){
                    $id = "$Name"
                    }
                    
                    $uri = "https://"+$ViprIP+":4443/block/exports/$id"

                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                }
            catch{

                Get-ViPRErrorMsg -errordata $result
            }

         $result
   
}


####Block Services####
Function Get-ViPRVolume{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

    $uri = "https://"+$ViprIP+":4443/block/volumes/search?name=$Name"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    $result = try{ 
    
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
        
                    $id = ($response.resource | Where match -eq $Name | Select).id

                     #Uses bogus ID if no match was found to trigger error
                    if(!$id){
                    $id = "$Name"
                    }
                    
                    $uri = "https://"+$ViprIP+":4443/block/volumes/$id"

                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                }
            catch{

               Get-ViPRErrorMsg -errordata $result
            }

         $result
}

#Returns array of Volume objects 
Function Get-ViPRVolumes{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)
    $object = @()
    $uri = "https://"+$ViprIP+":4443/block/volumes/bulk"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
   
    $result = try{  
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"  
                    $response | ForEach-Object{ 
                        $id = $_.id
                        $uri = "https://"+$ViprIP+":4443/block/volumes/$id"
                        $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
                        $object += $response
                    }
                    $object
                }
              catch{
                
                    Get-ViPRErrorMsg -errordata $result

              }
    $result
 }

#Gets Tags for a Snapshot
Function Get-ViPRVolumeTags{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$VolumeName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

  
  

    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    
    $result = try{  
                    $VolumeID = (Get-ViPRVolume -TokenPath $TokenPath -ViprIP $ViprIP -Name $VolumeName).id
                    $uri = "https://"+$ViprIP+":4443/block/volumes/$VolumeID/tags"
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
                    $response
                }
               catch{
                    Get-ViPRErrorMsg -errordata $result
               }
    $result
}

#Gets Tags for a Snapshot
Function Set-ViPRVolumeTag{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$VolumeName,
  [Parameter(Mandatory=$true)]
  [string]$Tag,
  [Parameter(Mandatory=$true)]
  [ValidateSet('Add','Remove')]
  [string]$Action,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

  $result = try{
                  $VolumeID = (Get-ViPRVolume -TokenPath $TokenPath -ViprIP $ViprIP -Name $VolumeName).id
                  $uri = "https://"+$ViprIP+":4443/block/volumes/$VolumeID/tags"
                  if($Action -eq 'Add'){
     
                      $jsonbody = '
                       {
                        "add": [
                          "'+$Tag+'"
                        ]
                      }'
                  }
                  elseif($Action -eq 'Remove'){
                      $jsonbody = '
                       {
                        "remove": [
                          "'+$Tag+'"
                        ]
                      }'

                  }
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    if($VolumeID){
                        $response = Invoke-RestMethod -Uri $uri -Method PUT -Body $jsonbody -Headers $headers -ContentType "application/json"
                        $response
                    }
                  }
            catch{
              Get-ViPRErrorMsg -errordata $result
            }
    $result
}

####Snapshot Services####
#Gets Snapshot information based on a name 
Function Get-ViPRSnapshot{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

    $uri = "https://"+$ViprIP+":4443/block/snapshots/search?name=$Name"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    $result = try{ 
    
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
        
                    $id = ($response.resource | Where match -eq $Name | Select).id

                     #Uses bogus ID if no match was found to trigger error
                    if(!$id){
                    $id = "$Name"
                    }
                    
                    $uri = "https://"+$ViprIP+":4443/block/snapshots/$id"

                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                }
            catch{

                Get-ViPRErrorMsg -errordata $result
            }

         $result

}

#Gets all snapshots related to a parent volume
Function Get-ViPRSnapshots{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$ParentVolumeName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

  $relatedsnaps = @()
  
  $result = try {   
                    
                    $parentvolume = (Get-ViPRVolume -TokenPath $TokenPath -ViprIP $ViprIP -Name $ParentVolumeName)
                    
                    $uri = "https://"+$ViprIP+":4443/block/snapshots/bulk"
                    
    
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    
                   if($parentvolume){
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
                    $snapshots = ($response.id) -split " "
                    Write-Output $snapshots
                    
                     $snapshots | ForEach{ 
                        $id = $_
                        $uri = "https://"+$ViprIP+":4443/block/snapshots/$id"
                        $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
                        if($response.parent.id -eq $parentvolume.id){
                        $relatedsnaps += $response
                        }
                    }

                    $relatedsnaps
                    }
                }
            
            catch{

                Get-ViPRErrorMsg -errordata $result
            }
    $result

}

#Gets Tags for a Snapshot
Function Get-ViPRSnapshotTags{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

     
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    $result = try{  
                    
                    $SnapshotID = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName).id
                    $uri = "https://"+$ViprIP+":4443/block/snapshots/$SnapshotID/tags"
                    if($SnapshotID){
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
                    $response
                    }
                }
               catch{
                    Get-ViPRErrorMsg -errordata $result
               }
    $result

}

#Gets Tags for a Snapshot
Function Set-ViPRSnapshotTag{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$Tag,
  [Parameter(Mandatory=$true)]
  [ValidateSet('Add','Remove')]
  [string]$Action,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

  
  $result = try{
                  $SnapshotID = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName).id
                  $uri = "https://"+$ViprIP+":4443/block/snapshots/$SnapshotID/tags"
                  if($Action -eq 'Add'){
     
                      $jsonbody = '
                       {
                        "add": [
                          "'+$Tag+'"
                        ]
                      }'
                  }
                  elseif($Action -eq 'Remove'){
                      $jsonbody = '
                       {
                        "remove": [
                          "'+$Tag+'"
                        ]
                      }'

                  }
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    if($SnapshotID){
                        $response = Invoke-RestMethod -Uri $uri -Method PUT -Body $jsonbody -Headers $headers -ContentType "application/json"
                        $response
                    }
                  }
            catch{
              Get-ViPRErrorMsg -errordata $result
            }
    $result

}
####UI Services - Order####

#Returns the order information given an order ID which will show status 
Function Get-ViPROrder{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$ID,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)
    $uri = "https://"+$ViprIP+":4443/catalog/orders/$ID"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    
    $result = try {
                    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"

                    $response
                 }
              catch{

                Get-ViPRErrorMsg -errordata $result

              }
    $result

}
Function New-ViPRSnapshot-Order{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$VolumeName,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [string]$TenantName,
  [Parameter(Mandatory=$true)]
  [string]$ProjectName
)

 $uri = "https://"+$ViprIP+":4443/catalog/orders"
 
 $result = try { 
                 $Tenant = (Get-ViPRTenant -TokenPath $TokenPath -ViprIP $ViprIP -Name $TenantName)
                 $TenantID = $Tenant.id

                 if($Tenant.code){
                    return $Tenant
                 }

                 if($TenantID){
                 $CatalogID = (Get-ViPRCatalogService -TenantID $TenantID -TokenPath $TokenPath -ViprIP $ViprIP -Name "CreateBlockSnapshot").id
                 }

                 $Volume = (Get-ViPRVolume -TokenPath $TokenPath -ViprIP $ViprIP -Name $VolumeName)
                 $VolumeID = $Volume.id

                 if($Volume.code){
                     return $Volume
                    }
                 
                 $Project = (Get-ViPRProject -TokenPath $TokenPath -ViprIP $ViprIP -Name $ProjectName)
                 $ProjectID = $Project.id

                 if($Project.code){
                    return $Project
                 }
 

                    $jsonbody = '
                    {
                    "tenantId": "'+$TenantID+'",
                    "parameters": [
                        {
                          "label": "project",
                          "value": "'+$ProjectID+'"
                        },
                        {
                          "label": "volumes",
                          "value": "'+$VolumeID+'"
                        },
                        {
                          "label": "type",
                          "value": "local"
                        },
                        {
                          "label": "name",
                          "value": "'+$SnapshotName+'"
                        }

                    ],
                     "catalog_service": "'+$CatalogID+'"
                   }'

    

                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }

                    


                   if($TenantID -and $VolumeID -and $CatalogID -and $ProjectID){
                     $response = (Invoke-RestMethod -Uri $uri -Method POST -Body $jsonbody -Headers $headers -ContentType "application/json")
                     $response
                     }
                    
                    
               }
            catch{
                
                
                Get-ViPRErrorMsg -errordata $result
                
            }
    $result

}

Function Remove-ViprSnapshot-Order{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [string]$TenantName,
  [Parameter(Mandatory=$true)]
  [string]$ProjectName
 
)

 $uri = "https://"+$ViprIP+":4443/catalog/orders"
 
 $result = try {
                 $Tenant = (Get-ViPRTenant -TokenPath $TokenPath -ViprIP $ViprIP -Name $TenantName)
                 $TenantID = $Tenant.id

                 if($Tenant.code){
                    return $Tenant
                 }

                 if($TenantID){
                    $CatalogID = (Get-ViPRCatalogService -TokenPath $TokenPath -TenantID $TenantID -ViprIP $ViprIP -Name "RemoveBlockSnapshot").id
                 }
                 
                 $Snapshot = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName)
                 $SnapshotID = $Snapshot.id

                 if($Snapshot.code){
                   return $Snapshot

                 }

                 $Project = (Get-ViPRProject -TokenPath $TokenPath -ViprIP $ViprIP -Name $ProjectName)
                 $ProjectID = $Project.id
                

                    $jsonbody = '
                    {
                    "tenantId": "'+$TenantID+'",
                    "parameters": [
                        {
                          "label": "project",
                          "value": "'+$ProjectID+'"
                        },
                        {
                          "label": "snapshots",
                          "value": "'+$SnapshotID+'"
                        }

                    ],
                     "catalog_service": "'+$CatalogID+'"
                   }'


                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    if($TenantID -and $ProjectID -and $SnapshotID -and $CatalogID){
                         $response = (Invoke-RestMethod -Uri $uri -Method POST -Body $jsonbody -Headers $headers -ContentType "application/json")
                         $response
                    }
                    
               }
            catch{

              Get-ViPRErrorMsg -errordata $result
            }
    $result
}

Function Export-ViPRSnapshot-Order{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [string]$HostName,
  [Parameter(Mandatory=$true)]
  [string]$TenantName,
  [Parameter(Mandatory=$true)]
  [string]$ProjectName,
  [Parameter(Mandatory=$true)]
  [string]$HLU,
  [Parameter(Mandatory=$true)]
  [ValidateSet('exclusive','shared')]
  [string]$StorageType
)
  if($StorageType -eq 'exclusive'){
  $HostType = 'Standalone'
  }
  else{
  $HostType = 'Cluster'
  }
  $result = try {
                 
                 $Tenant = (Get-ViPRTenant -TokenPath $TokenPath -ViprIP $ViprIP -Name $TenantName)
                 $TenantID = $Tenant.id

                 if($Tenant.code){
                    return $Tenant
                 }


                 if($TenantID){
                 $CatalogID = (Get-ViPRCatalogService -TenantID $TenantID -TokenPath $TokenPath -ViprIP $ViprIP -Name "ExportSnapshottoaHost").id
                 }

                 $Snapshot = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName)
                 $SnapshotID =$Snapshot.id


                 if($Snapshot.code){
                    return $Snapshot
                 }
                 

                 $Host = (Get-ViPRHost -TokenPath $TokenPath -ViprIP $ViprIP -Name $HostName -HostType $HostType)
                 $HostID = $Host.id

                 if($Host.code){

                    return $Host
                 }
                 
                 $Project = (Get-ViPRProject -TokenPath $TokenPath -ViprIP $ViprIP -Name $ProjectName)
                 $ProjectID = $Project.id

                 if($Project.code){

                    return $Project
                 }
 

                 $uri = "https://"+$ViprIP+":4443/catalog/orders"
                 $jsonbody = '
                 {
                    "tenantId": "'+$TenantID+'",
                    "parameters": [
                        {
                          "label": "storageType",
                          "value": "'+$StorageType+'"
                        },
                        {
                          "label": "host",
                          "value": "'+$HostID+'"
                        },
                        {
                          "label": "project",
                          "value": "'+$ProjectID+'"
                        },
                        {
                          "label": "snapshots",
                          "value": "'+$SnapshotID+'"
                        },
                        {
                          "label": "hlu",
                          "value": "'+$HLU+'"

                        }

                    ],
                     "catalog_service": "'+$CatalogID+'"}'
    
    
    
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    if($HostID -and $ProjectID -and $SnapshotID -and $TenantID -and $CatalogID){
                        $response = Invoke-RestMethod -Uri $uri -Method POST -Body $jsonbody -Headers $headers -ContentType "application/json"
                        $response
                    }
                    
                }
           catch{

                Get-ViPRErrorMsg -errordata $result
           }
    $result
    
}

Function Unexport-ViPRSnapshot-Order{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [string]$HostName,
  [Parameter(Mandatory=$true)]
  [string]$TenantName,
  [Parameter(Mandatory=$true)]
  [string]$ProjectName
 
)
 $result = try {
                 
                 $Tenant = (Get-ViPRTenant -TokenPath $TokenPath -ViprIP $ViprIP -Name $TenantName)
                 $TenantID = $Tenant.id

                 if($Tenant.code){
                    return $Tenant
                 }
                 
                 if($TenantID){
                 $CatalogID = (Get-ViPRCatalogService -TenantID $TenantID -TokenPath $TokenPath -ViprIP $ViprIP -Name "UnexportSnapshot").id
                 }
                 
                 $Snapshot = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName)
                 $SnapshotID = $Snapshot.id

                 if($Snapshot.code){

                    return $Snapshot
                 }

                 $Export = (Get-ViprExportGroup -TokenPath $TokenPath -ViprIP $ViprIP -Name $HostName)
                 $ExportID = $Export.id

                 if($Export.code){

                    return $Export
                 }

                 $Project = (Get-ViPRProject -TokenPath $TokenPath -ViprIP $ViprIP -Name $ProjectName)
                 $ProjectID = $Project.id
 

                 $uri = "https://"+$ViprIP+":4443/catalog/orders"
                 $jsonbody = '
                 {
                    "tenantId": "'+$TenantID+'",
                    "parameters": [
                        {
                          "label": "export",
                          "value": "'+$ExportID+'"
                        },
                        {
                          "label": "project",
                          "value": "'+$ProjectID+'"
                        },
                        {
                          "label": "snapshot",
                          "value": "'+$SnapshotID+'"
                        }
                    ],
                     "catalog_service": "'+$CatalogID+'"}'
    
    
    
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    
                    if($TenantID -and $ExportID -and $ProjectID -and $SnapshotID -and $CatalogID){
                        $response = Invoke-RestMethod -Uri $uri -Method POST -Body $jsonbody -Headers $headers -ContentType "application/json"
                        $response
                    }
                    
                }
          catch {

            Get-ViPRErrorMsg -errordata $result
          }
    $result

}

Function Mount-ViPRWindowsVolume-Order{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [string]$HostName,
  [Parameter(Mandatory=$true)]
  [string]$TenantName,
  [Parameter(Mandatory=$true)]
  [string]$ProjectName,
  [Parameter(Mandatory=$true)]
  [ValidateSet('exclusive','shared')]
  [string]$StorageType,
  [Parameter(Mandatory=$true)]
  [ValidateSet('gpt','mbr')]
  [string]$PartitionType,
  [Parameter(Mandatory=$true)]
  [ValidateSet('ntfs','fat32')]
  [string]$FileSystemType,
  [Parameter()]
  [string]$DriveLabel =" ",
  [Parameter()]
  [string]$MountPoint=" "
)

if($StorageType -eq 'exclusive'){
  $HostType = 'Standalone'
  }
  else{
  $HostType = 'Cluster'
  }

  $result = try {
                 
                 $Tenant = (Get-ViPRTenant -TokenPath $TokenPath -ViprIP $ViprIP -Name $TenantName)
                 $TenantID = $Tenant.id

                 if($Tenant.code){
                    return $Tenant
                 }


                 if($TenantID){
                    $CatalogID = (Get-ViPRCatalogService -TenantID $TenantID -TokenPath $TokenPath -ViprIP $ViprIP -Name "MountVolumeOnWindows").id
                 }

                 $Snapshot = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName)
                 $SnapshotID = $Snapshot.id

                 if($Snapshot.code){
                    return $Snapshot
                 }

                 $Host = (Get-ViPRHost -TokenPath $TokenPath -ViprIP $ViprIP -Name $HostName -HostType $HostType)
                 $HostID = $Host.id

                 if($Host.code){
                    return $Host
                 }

                 $Project = (Get-ViPRProject -TokenPath $TokenPath -ViprIP $ViprIP -Name $ProjectName)
                 $ProjectID = $Project.id

                 if($Project.code){
                    return $Project
                 }
                

                 $uri = "https://"+$ViprIP+":4443/catalog/orders"
                 $jsonbody = '
                 {
                    "tenantId": "'+$TenantID+'",
                    "parameters": [
                        {
                          "label": "blockStorageType",
                          "value": "'+$StorageType+'"
                        },
                        {
                          "label": "host",
                          "value": "'+$HostID+'"
                        },
                        {
                          "label": "project",
                          "value": "'+$ProjectID+'"
                        },
                        {
                          "label": "volume",
                          "value": "'+$SnapshotID+'"
                        },
                        {
                          "label": "fileSystemType",
                          "value": "'+$FileSystemType+'"
                        },
                        {
                          "label": "doFormat",
                          "value": "false"
                        },
                        {
                          "label": "partitionType",
                          "value": "'+$PartitionType+'"
                        },
                        {
                          "label": "blockSize",
                          "value": "default"
                        },
                        {
                          "label": "mountPoint",
                          "value": "'+$MountPoint+'"
                        },
                        {
                          "label": "label",
                          "value": "'+$DriveLabel+'"
                        }        
                    ],
                     "catalog_service": "'+$CatalogID+'"}'
    
    
    
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    if($ProjectID -and $CatalogID -and $TenantID -and $HostID -and $SnapshotID){
                        $response = Invoke-RestMethod -Uri $uri -Method POST -Body $jsonbody -Headers $headers -ContentType "application/json"
                        $response
                    }
                    
               }
        catch{
            
            Get-ViPRErrorMsg -errordata $result

        }
   $result
    
}

Function Unmount-ViPRWindowsVolume-Order{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$SnapshotName,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath,
  [Parameter(Mandatory=$true)]
  [string]$HostName,
  [Parameter(Mandatory=$true)]
  [string]$TenantName,
  [Parameter(Mandatory=$true)]
  [string]$ProjectName,
  [Parameter(Mandatory=$true)]
  [ValidateSet('exclusive','shared')]
  [string]$StorageType
)

if($StorageType -eq 'exclusive'){
  $HostType = 'Standalone'
  }
  else{
  $HostType = 'Cluster'
  }
                
   $result = try {           
                 
                 $Tenant = (Get-ViPRTenant -TokenPath $TokenPath -ViprIP $ViprIP -Name $TenantName)
                 $TenantID = $Tenant.id

                 if($Tenant.code){
                    return $Tenant
                 }

                 if($TenantID){
                 $CatalogID = (Get-ViPRCatalogService -TenantID $TenantID -TokenPath $TokenPath -ViprIP $ViprIP -Name "UnmountVolumeOnWindows").id
                 }

                 $Snapshot = (Get-ViPRSnapshot -TokenPath $TokenPath -ViprIP $ViprIP -Name $SnapshotName)
                 $SnapshotID = $Snapshot.id

                 if($Snapshot.code){
                    return $Snapshot
                 }

                 $Host = (Get-ViPRHost -TokenPath $TokenPath -ViprIP $ViprIP -Name $HostName -HostType $HostType)
                 $HostID = $Host.id

                 if($Host.code){
                    return $Host
                 }

                 $Project = (Get-ViPRProject -TokenPath $TokenPath -ViprIP $ViprIP -Name $ProjectName)
                 $ProjectID = $Project.id

                 if($Project.code){
                    return $Project
                 }
                 

                 $uri = "https://"+$ViprIP+":4443/catalog/orders"
                 $jsonbody = '
                 {
                    "tenantId": "'+$TenantID+'",
                    "parameters": [
                        {
                          "label": "blockStorageType",
                          "value": "'+$StorageType+'"
                        },
                        {
                          "label": "host",
                          "value": "'+$HostID+'"
                        },
                        {
                          "label": "volumes",
                          "value": "'+$SnapshotID+'"
                        }        
                    ],
                     "catalog_service": "'+$CatalogID+'"}'
    
    
                    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
                    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
                    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
                    
                     $response = Invoke-RestMethod -Uri $uri -Method POST -Body $jsonbody -Headers $headers -ContentType "application/json"
                     $response
                    
                }
        catch {
            
            Get-ViPRErrorMsg -errordata $result

        }
    $result
    
}

#Checks order status until it has a successful or failure state, then returns the order information
Function Get-ViPROrderStatus{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [string]$ViprIP,
  [Parameter(Mandatory=$true)]
  [string]$OrderID,
  [Parameter(Mandatory=$true)]
  [string]$TokenPath
)

     ###Monitor the status, wait until it's no longer running
    $status = "Pending"

    While($status -eq "Pending" -or $status -eq "Execute" -or $status -eq "Executing"){
      $progress = (Get-ViPROrder -ViprIP $ViprIP -ID $OrderID -TokenPath $TokenPath)
      $status = $progress.order_status
      $summary = $progress.summary
      $parameters = $progress.parameters
      $date = Get-Date -Format s
      Write-Verbose "$date Currently Executing: $summary"
      Write-Verbose "$date Current Status: $status"
  
      Start-Sleep -Seconds 5
    }
    $ordernumber = $progress.order_number
    ###Get the order, should return all of the things we need including the final status and new resource IDs
    If($status -eq "FAILED" -or $status -eq "ERROR"){
        $date = Get-Date -Format s
        $message = $progress.message
        Write-Verbose "$date ERROR: $summary failed for Order Number $ordernumber - ID $OrderID"
        Write-Verbose "$date ERROR: $message"
        Get-ViPROrder -ViprIP $ViprIP -ID $OrderID -TokenPath $TokenPath
    }
    else{

    #Return the order, it completed
    $date = Get-Date -Format s
    Write-Verbose "$date $summary Completed Successfuly for Order Number $ordernumber - ID $OrderID "
    Get-ViPROrder -ViprIP $ViprIP -ID $OrderID -TokenPath $TokenPath
    }
    
}

####UI Services - Catalog Services####
Function Get-ViPRCatalogService{
 [Cmdletbinding()]
 Param(
 [Parameter(Mandatory=$true)]
 [string]$ViprIP,
 [Parameter(Mandatory=$true)]
 [string]$TokenPath,
 [Parameter(Mandatory=$true)]
 [string]$Name,
 [Parameter(Mandatory=$true)]
 [string]$TenantID
 )

 $uri = "https://"+$ViprIP+":4443/catalog/services/search?name=$Name"

    
    $authtoken = Get-Content -Path "$TokenPath\viprauthtoken.txt"
    $proxytoken = Get-Content -Path "$TokenPath\viprproxytoken.txt"
    $headers = @{ "X-SDS-AUTH-PROXY-TOKEN"=$proxytoken; "X-SDS-AUTH-TOKEN"=$authtoken; "Accept"="Application/JSON" }
    
    $result = try{
                    $catalogservices = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ContentType "application/json"
  
                    $catalogservices.resource | ForEach-Object{
                        $href = $_.link.href
       
                        $serviceuri = "https://"+$ViprIP+":4443$href"
       
                        $response = Invoke-RestMethod -Uri $serviceuri -Method GET -Headers $headers -ContentType "application/json"
        
                        $categoryhref = $response.catalog_category.link.href
                        $categoryuri = "https://"+$ViprIP+":4443$categoryhref"
        

                        $response = Invoke-RestMethod -Uri $categoryuri -Method GET -Headers $headers -ContentType "application/json"
        
                        if($response.tenant.id -eq $TenantID){
                             return $_
            
                        }

        
                    }
                  }
            catch{

                Get-ViPRErrorMsg -errordata $result

            }
    $result

}


####Helpers####

#Generates Basic Auth base64 header
Function Get-AuthHeader([string]$username,[string]$password){
 
  $basicAuth = ("{0}:{1}" -f $username,$password)
  $basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
  $basicAuth = [System.Convert]::ToBase64String($basicAuth)
  $headers = @{Authorization=("Basic {0}" -f $basicAuth)}

  return $headers
 
}

#Can be used to determine API errors
Function Get-ViPRErrorMsg([AllowNull()][object]$errordata){   
    $ed = $errordata
    
  try{ 
    $ed = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($ed)
    $responseBody = $reader.ReadToEnd(); 
    $errorcontent = $responseBody
    $errormsg = $errorcontent | ConvertFrom-Json
    
   Write-Error $errorcontent
   $errormsg
    
    
    }
   catch{
    $catchall = '
    { "code" : "404",
      "description" : "Catch all",
      "details": "Possible IP resolution or HTTP error"
    }'
    
    return $catchall | ConvertFrom-Json
    
   } 
  
}
