#!/bin/bash

#aws ec2 describe-images --executable-users self


#user input image
echo Template Provisioning. Please input Image ID:

read imageid


#describe image output to json | parse snapshot-id
aws ec2 describe-images --image-ids $imageid > json/old_image.json

snapshotid=`cat 'json/old_image.json' | jq -r .'Images[].BlockDeviceMappings[] | select(.Ebs).Ebs.SnapshotId'`
imagename=`cat 'json/old_image.json' | jq -r .'Images[].Name'`

echo Snapshot-ID: $snapshotid
echo Image Name: $imagename


#describe volumes filter snapshot id | parse volumeid
aws ec2 describe-volumes --filters Name=snapshot-id,Values=$snapshotid > json/old_volume.json

volumeid=`cat 'json/old_volume.json' | jq -r .'Volumes[].Attachments[].VolumeId'`
instanceid=`cat 'json/old_volume.json' | jq -r .'Volumes[].Attachments[].InstanceId'`

echo Volume ID: $volumeid
echo Instance ID: $instanceid


#describe instance | parse launch template (?)
aws ec2 describe-instances --instance-ids $instanceid > json/instance.json

lt=`cat 'json/instance.json' | jq -r .'Reservations[].Instances[].Tags[] | select(.Key == "aws:ec2launchtemplate:id") | .Value'`
instancename=`cat 'json/instance.json' | jq -r .'Reservations[].Instances[].Tags[] | select(.Key == "Name") | .Value'`


echo Instance Name: $instancename
echo Launch Template: $lt



#describe launch template | parse name
aws ec2 describe-launch-templates --launch-template-ids $lt > json/launchtemplate.json

ltname=`cat 'json/launchtemplate.json' | jq -r .'LaunchTemplates[].LaunchTemplateName'`


echo Launch Template Name: $ltname


#get existing launch template data
aws ec2 get-launch-template-data --instance-id $instanceid --query 'LaunchTemplateData' > json/launchtemplate.json


#error check

errorcheck=`cat 'json/launchtemplate.json' | jq -r .'ImageId'`

printf "Is this the right AMI: $errorcheck \nStarting in 20s...\n"
sleep 10s
printf "10s\n"
sleep 5s
printf "5s\n"
sleep 5s
printf "Provisioning.\n"

if [ "$imageid" == "$errorcheck" ];

	then
		#deregister old image
		echo Deregister old image...
		aws ec2 deregister-image --image-id $imageid > json/output.json

		#create new image > output to new.json
		echo Create new image...
		aws ec2 create-image --instance-id $instanceid --name "$imagename" > json/new_image.json

		newimageid=`cat 'json/new_image.json' | jq -r .'ImageId'`

		#wait for image ready
		echo Pending image availability...
		aws ec2 wait image-available --image-ids $newimageid >> json/output.json

		#delete old snapshot
		echo Deleting old snapshot...
		aws ec2 delete-snapshot --snapshot-id $snapshotid >> json/output.json

		#delete old template
		echo Deleting old launch template...
		aws ec2 delete-launch-template --launch-template-id $lt >> json/output.json

		#replacing ami with new value
		cat 'json/launchtemplate.json' | jq --arg newimage $newimageid .'ImageId = $newimage' > json/launchtemplate.tmp && mv json/launchtemplate.tmp json/launchtemplate.json

		#create new template
		echo Creating new Launch Template...
		aws ec2 create-launch-template --launch-template-name "$ltname" --launch-template-data file://json/launchtemplate.json >> json/output.json

		echo Provisioning Complete!
else

		echo "Error!"

fi
