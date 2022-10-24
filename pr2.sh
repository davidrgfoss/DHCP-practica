#!/usr/bin/env bash

sleep 120

if [ -f /home/davidrg/.ssh/id_rsa ]
then
	sleep 1
else
	echo "1" | su davidrg -c 'ssh-keygen -t rsa -N "" -f /home/davidrg/.ssh/id_rsa'
fi

echo "1" | sudo -S dhcp-lease-list --parsable | cut -d " " -f 4,6 | tr -t "  " "\n" > /tmp/pr1; chmod 777 /tmp/pr1; touch /tmp/use; sudo chmod 777 /tmp/use; touch /tmp/pr2; chmod 777 /tmp/pr2; touch /tmp/machine; chmod 777 /tmp/machine; chmod -R 777 /tmp/ansible/; chown davidrg:davidrg /home/davidrg/.ssh/id_rsa*

while read x;
do
	if [[ $x =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];
	then
		aux="$x"
	else
		#if [ $x == "server-web" ];
		#then
		#	echo -e "web_server: $aux" > /tmp/dhcp-ansible/group_vars/all
		#fi
		echo -e "$x" >> /tmp/machine
		echo -e "davidrg@$aux" >> /tmp/pr2
		echo -e "Maquina: $x con IP: $aux" >> /tmp/use
	fi
done < /tmp/pr1

sshpass -p 1 ssh-copy-id davidrg@10.0.0.2
echo "1" | ssh -tt davidrg@10.0.0.2 "sudo cp -Rf /etc/sudoers /tmp/sudoers; sudo chmod 777 /tmp/sudoers; echo -e '\ndavidrg ALL=(ALL) NOPASSWD: ALL' >> /tmp/sudoers; sudo chmod 440 /tmp/sudoers; sudo cp -Rf /tmp/sudoers /etc/sudoers"

while read x;
do
	sshpass -p 1 ssh-copy-id $x
	echo "1" | ssh -tt $x "sudo cp -Rf /etc/sudoers /tmp/sudoers; sudo chmod 777 /tmp/sudoers; echo -e '\ndavidrg ALL=(ALL) NOPASSWD: ALL' >> /tmp/sudoers; sudo chmod 440 /tmp/sudoers; sudo cp -Rf /tmp/sudoers /etc/sudoers"
done < /tmp/pr2

numaux=`wc -l /tmp/use | cut -d " " -f 1`
p="p"

for x in `seq $numaux`;
do
	echo -e "`cat /tmp/use | cut -d " " -f2 | sed -n $x$p` ansible_host=`cat /tmp/use | cut -d " " -f5 | sed -n $x$p` ansible_port=22 ansible_user='davidrg' ansible_ssh_private_key_file='/home/davidrg/.ssh/id_rsa'" >> /tmp/ansible/hosts

done

echo -e "\n" >> /tmp/ansible/hosts
echo -e "[clientes]" >> /tmp/ansible/hosts

for x in `seq $numaux`;
do
	echo -e "`cat /tmp/use | cut -d " " -f2 | sed -n $x$p`" >>  /tmp/ansible/hosts
done

rm -Rf /tmp/pr*
rm -Rf /tmp/machine

ansible-playbook /tmp/ansible/site.yaml -i /tmp/ansible/hosts

