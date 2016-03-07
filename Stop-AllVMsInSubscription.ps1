<#
.DESCRIPTION
    Stops and Deallocate ALL classic and ARM VMs within a given subscription
    Checks if the VMs are allready deallocated or stopped, and if they are the script dosen't attempt to stop it. 
.NOTES
    AUTHOR: Rune Møller Kjerri rune.kjerri@crayon.com
    LASTEDIT: March 7, 2016 
    
#>
workflow Stop-AllVMsInSubscription
{
    
    Param(
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionName = "Intranet for Rene",
    
        [Parameter(Mandatory=$true)]
        [string]$AutomationCredential = "IntranetCred"
    )
    
    $Cred = Get-AutomationPSCredential -Name $AutomationCredential
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${AutomationCredential}'. Make sure you have created one in this Automation Account."
    }

    parallel{
        #Stop ALL Classic VMs
        sequence{
                $ClassicAccount = Add-AzureAccount -Credential $Cred
                if(!$ClassicAccount) {
                    Throw "Could not authenticate to Azure using the credential asset '${AutomationCredential}'. Make sure the user name and password are correct."
                }
                
                Select-AzureSubscription  -SubscriptionName $SubscriptionName
                
                $ClassicVMs = Get-AzureVM
                #$ClassicVMs.

                #Write-Output($ClassicVMs.Name)
                foreach($VM in $ClassicVMs){

                    if(!$VM){
                    Write-Debug($VM.Name  + ' dosen''t exist') -debug
                    }
                    if($VM.Status -eq 'StoppedDeallocated')
                    {
                        Write-Output("Classic VM " + $VM.name + " is already deallocated or stopped")
                        }else{
                        Write-Output('Killing Classic VM: ' +  $VM.Name)
                        Stop-AzureVM -Name $VM.name -ServiceName $VM.name -force 
                    }
                }
                        
        }#/sequence
        
        #Stop ARM VMS
        sequence{
            InlineScript{
                $ARMAccount = Add-AzureRmAccount -credential $using:Cred -SubscriptionName $using:SubscriptionName
          
                if(!$ARMAccount) {
                    Throw "Could not authenticate to Azure using the credential asset $using:AutomationCredential. Make sure the user name and password are correct."
                }
                $ARMAccount.Context.Subscription
                Set-AzureRmContext -Context $ARMAccount.Context
                            
                $ResourceMangerVMs = Get-AzureRmVM
                
                foreach($VM in $ResourceMangerVMs){
                    if(!$VM){
                        Write-Debug "$VM dosen''t exist" -debug
                    }
                    $StatusVM = Get-AzureRmVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Status

                    if($StatusVM.Statuses.code -eq "PowerState/deallocated" -or $StatusVM.Statuses.code -eq "PowerState/stopped"){
                    
                         Write-Output("ARM VM " + $VM.name + " is already deallocated or stopped")
                    }else{
                        Write-Output('Killing ARM VM: '  + $VM.name +  ' in ' + $VM.ResourceGroupName)
                        Stop-AzureRmVM -Name $VM.name -ResourceGroupName $VM.ResourceGroupName -force
                    }
  
                }#/foreach
            }#/inline
            
        }#/Sequence
    } #/Paralell
    
}