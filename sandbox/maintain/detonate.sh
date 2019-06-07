#!/bin/bash

dc_instance=`cat ~/sandbox/scripts/domaincontroller.json | jq -r '.Instances[].InstanceId'`
win_instance=`cat ~/sandbox/scripts/windows_instance.json | jq -r '.Instances[].InstanceId'`

echo "Which instance should we blow up today? Enter a number."
echo "1) Domain Controller"
echo "2) Windows Server"
echo "3) all of the above"
echo ""
echo "Press any key to cancel."

read -n 1 instancename

echo ""

if [ $instancename = 1 ]; then
   
   echo "OK. Terminating Instance..."
   aws ec2 terminate-instances --instance-ids $dc_instance > /dev/null

   echo "Please wait..."
   aws ec2 wait instance-terminated --instance-ids $dc_instance

   echo "Instance shutdown. Rebuilding new sandbox..."
   aws ec2 run-instances --launch-template LaunchTemplateName=dc_lt,Version=1 > ~/sandbox/scripts/domaincontroller.json

   echo "30 more seconds..."
   sleep 30s

   echo "Done. Thanks!"
   sleep 5s

elif [ $instancename = 2 ]; then
   
   echo "OK. Terminating Instance..."
   aws ec2 terminate-instances --instance-ids $win_instance > /dev/null

   echo "Please wait..."
   aws ec2 wait instance-terminated --instance-ids $win_instance

   echo "Instance shutdown. Rebuilding new sandbox..."
   aws ec2 run-instances --launch-template LaunchTemplateName=windows_lt,Version=1 > ~/sandbox/scripts/windows_instance.json

   echo "30 more seconds..."
   sleep 30s

   echo "Done. Thanks!"
   sleep 5s

elif [ $instancename = 3 ]; then

   echo "OK. Terminating Instances..."
   aws ec2 terminate-instances --instance-ids $dc_instance $win_instance > /dev/null

   echo "Please wait..."
   aws ec2 wait instance-terminated --instance-ids $dc_instance $win_instance

   echo "Instances shutdown. Rebuilding new sandbox..."
   aws ec2 run-instances --launch-template LaunchTemplateName=dc_lt,Version=1 > ~/sandbox/scripts/domaincontroller.json
   aws ec2 run-instances --launch-template LaunchTemplateName=windows_lt,Version=1 > ~/sandbox/scripts/windows_instance.json

   echo "30 more seconds..."
   sleep 30s

   echo "Done. Thanks!"
   sleep 5s

else
     echo "Invalid input. Exiting!"
     sleep 5s
fi	
