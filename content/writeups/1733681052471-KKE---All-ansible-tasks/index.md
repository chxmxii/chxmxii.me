---
title: "KKE - All ansible tasks"
date: 2022-12-20
draft: false
description: "Writeups for all ansible challenges from the kodekloud platform"
tags: ["Ansible", "DevOps"]
---

KodeKloud Engineer is a platform for students to gain real hands-on experience with DevOps skills.

{{< button href="https://kodekloud-engineer.com/#!/tasks" target="_self" >}}
Visit the KKE platform!{{< /button >}}

## Ansible Unarchive Module	

+ One of the DevOps team members has created an ZIP archive on jump host in Stratos DC that needs to be extracted and copied over to all app servers in Stratos DC itself. Because this is a routine task, the Nautilus DevOps team has suggested automating it. We can use Ansible since we have been using it for other automation tasks. Below you can find more details about the task:
+ We have an inventory file under /home/thor/ansible directory on jump host, which should have all the app servers added already.
+ There is a ZIP archive /usr/src/devops/nautilus.zip on jump host.
+ Create a playbook.yml under /home/thor/ansible/ directory on jump host itself to perform the below given tasks.
+ Unzip /usr/src/devops/nautilus.zip archive in /opt/devops/ location on all app servers.
+ Make sure the extracted data must has the respective sudo user as their user and group owner, i.e tony for app server 1, steve for app server 2, banner for app server 3.
+ The extracted data permissions must be 0644
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure playbook works this way, without passing any extra arguments.

###### Solution:
+ ```Shell
  #verify the connectivity 
  ansible all -m ping -i inventory
  #create a playbook.yml
  #run the playbook
  ansible-playbook -i inventory playbook.yml
  ```
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - unarchive:
          src: /usr/src/sysops/xfusion.zip
          dest: /opt/sysops/
          mode: '0744'
          owner: tony
          group: tony
        when: ansible_hostname == "stapp01"
      - unarchive:
          src: /usr/src/sysops/xfusion.zip
          dest: /opt/sysops/
          mode: '0744'
          owner: steve
          group: steve
        when: ansible_hostname == "stapp02"
      - unarchive:
          src: /usr/src/sysops/xfusion.zip
          dest: /opt/sysops/
          mode: '0744'
          owner: banner
          group: banner
        when: ansible_hostname == "stapp03"
  ...
  ```
---
## Ansible Facts Gathering

+ The Nautilus DevOps team is trying to setup a simple Apache web server on all app servers in Stratos DC using Ansible. They also want to create a sample html page for now with some app specific data on it. Below you can find more details about the task.
+ You will find a valid inventory file /home/thor/playbooks/inventory on jump host (which we are using as an Ansible controller).
+ Create a playbook index.yml under /home/thor/playbooks directory on jump host. Using blockinfile Ansible module create a file facts.txt under /root directory on all app servers and add the following given block in it. You will need to enable facts gathering for this task.
Ansible managed node IP is <default ipv4 address>
(You can obtain default ipv4 address from Ansible's gathered facts by using the correct Ansible variable while taking into account Jinja2 syntax)
+ Install httpd server on all apps. After that make a copy of facts.txt file as index.html under /var/www/html directory. Make sure to start httpd service after that.
Note: Do not create a separate role for this task, just add all of the changes in index.yml playbook.

###### Solution:
+ ```yaml
  ---
  - hosts: all
    become: true
    gather_facts: true
    tasks:
      - file:
          path: /root/facts.txt
          state: touch
      - blockinfile:
          dest: /root/facts.txt
          block: "Ansible managed node IP is {{ansible_default_ipv4['address']}}"
      - package:
          name: httpd
          state: installed
      - copy:
          remote_src: yes
          src: /root/facts.txt
          dest: /var/www/html/index.html
      - service:
          name: httpd
          state: started  
  ```
---
## Puppet Create Symlinks

+ Some directory structure in the Stratos Datacenter needs to be changed, there is a directory that needs to be linked to the default Apache document root. We need to accomplish this task using Puppet, as per the instructions given below:
+ Create a puppet programming file official.pp under /etc/puppetlabs/code/environments/production/manifests directory on puppet master node i.e on Jump Server. Within that define a class symlink and perform below mentioned tasks:
+ Create a symbolic link through puppet programming code. The source path should be /opt/itadmin and destination path should be /var/www/html on Puppet agents 2 i.e on App Servers 2.
Create a blank file media.txt under /opt/itadmin directory on puppet agent 2 nodes i.e on App Servers 2.
+ Notes:
  + Please make sure to run the puppet agent test using sudo on agent nodes, otherwise you can face certificate issues. In that case you will have to clean the certificates first and then you will be able to run the puppet agent test. 
  + Before clicking on the Check button please make sure to verify puppet server and puppet agent services are up and running on the respective servers, also please make sure to run puppet agent test to apply/test the changes manually first.
+ P lease note that once lab is loaded, the puppet server service should start automatically on puppet master server, however it can take upto 2-3 minutes to start.

###### Solution
+ ```shell
  sudo vi /etc/puppetlabs/code/environments/production/manifests/official.pp
  #verify the syntax
  puppet parser validate /etc/puppetlabs/code/environments/production/manifests/official.pp
  #run on the agent 2
  sshpass -p Am3ric@ ssh -o StrictHostKeyChecking=no steve@stapp02
  sudo puppet agent -tv
  #verify
  ls -lrt /var/www/html
  ls -lrt /opt/itadmin
  ```
+ ```js
  class symlink {
    //create sym link
    file{'/opt/itadmin':
      ensure => 'link',
      target => '/var/www/html',
    }
    //create file media.txt
    file{'/opt/itadmin/media.txt':
      ensure => 'present';
    }
  }

  node 'stapp01.stratos.xfusioncorp.com', 'stapp02.stratos.xfusioncorp.com', 'stapp03.stratos.xfusioncorp.com' {
    include symlink
  }
  ```
---
## Ansible Basic Playbook

+ One of the Nautilus DevOps team members was working on to test an Ansible playbook on jump host. However, he was only able to create the inventory, and due to other priorities that came in he has to work on other tasks. Please pick up this task from where he left off and complete it. Below are more details about the task:
+ The inventory file /home/thor/ansible/inventory seems to be having some issues, please fix them. The playbook needs to be run on App Server 2 in Stratos DC, so inventory file needs to be updated accordingly.
+ Create a playbook /home/thor/ansible/playbook.yml and add a task to create an empty file /tmp/file.txt on App Server 2.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please mak
  
###### Solution:
+ ```shell
  #fix the inventory file by adding the ssh user and sshpass
  stapp02 ansible_host=172.16.238.11 ansible_ssh_user=steve ansible_ssh_pass=Am3ric@ #remote_user=steve
  #verify
  ansible stapp02 -m ping -i ansible/inventory
  #now lets write the playbook
  vi ansible/playboo.yml
  #run the playbook
  ansible-playbook playbook.yml -i inventory
  ```
+ ```yaml
  ---
  - hosts: stapp02
    tasks:
      - file:
          dest: /tmp/file.txt
          state: touch
  ```
---
## Ansible Inventory Update

+ The Nautilus DevOps team has started testing their Ansible playbooks on different servers within the stack. They have placed some playbooks under /home/thor/playbook/ directory on jump host which they want to test. Some of these playbooks have already been tested on different servers, but now they want to test them on app server 1 in Stratos DC. However, they first need to create an inventory file so that Ansible can connect to the respective app. Below are some requirements:
+ a. Create an ini type Ansible inventory file /home/thor/playbook/inventory on jump host.
+ b. Add App Server 1 in this inventory along with required variables that are needed to make it work.
+ c. The inventory hostname of the host should be the server name as per the wiki, for example stapp01 for app server 1 in Stratos DC.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way without passing any extra arguments.

###### Solution
+ ```Shell
  cd playbooks
  echo "stapp01 ansible_user=tony ansible_password=Ir0nM@n" > inventory
  ansible-playbook -i inventory playbook.yml
  ```
---
## Ansible Config File Update

+ To manage all servers within the stack using Ansible, the Nautilus DevOps team is planning to use a common sudo user among all servers. Ansible will be able to use this to perform different tasks on each server. This is not finalized yet, but the team has decided to first perform testing. The DevOps team has already installed Ansible on jump host using yum, and they now have the following requirement:
+ On jump host make appropriate changes so that Ansible can use kirsty as a default ssh user for all hosts. Make changes in Ansible's default configuration only —please do not try to create a new config.

###### Solution:
+ ```Shell
  thor@jump_host ~$ ansible --version
  ansible 2.9.9
    config file = /etc/ansible/ansible.cfg
  thor@jump_host ~$ sudo vi /etc/ansible.cfg
  > search for "#remote_user=root" and change it to "remote_user=kirst"
  #verify
  ansible-config dump | grep USER 
  ```
---
## Ansible Copy Module

+ There is data on jump host that needs to be copied on all application servers in Stratos DC. Nautilus DevOps team want to perform this task using Ansible. Perform the task as per details mentioned below:
+ a. On jump host create an inventory file /home/thor/ansible/inventory and add all application servers as managed nodes.
+ b. On jump host create a playbook /home/thor/ansible/playbook.yml to copy /usr/src/finance/index.html file to all application servers at location /opt/finance.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way without passing any extra arguments.

###### Solution
+ ```Shell
  ansible --version
  echo "stapp01 ansible_user=tony ansible_password=Ir0nM@n" > ansible/inventory
  echo "stapp02 ansible_user=steve ansible_password=Am3ric@" >> ansible/inventory
  echo "stapp03 ansible_user=banner ansible_password=BigGr33n" >> ansible/inventory
  ansible all -i ansible/inventory  -m ping
  vi ansible/playbook.yml
  ansible-playbook -i ansible/inventory -C ansible/playbook.yml
  ansible-playbook -i ansible/inventory ansible/playbook.yml
  ansible all -i ansible/inventory -a "cat /opt/finance/index.html"
  ```
+ ```yaml
  ---
  - hosts: all
    gather_facts: no
    become: true
    tasks:
      - copy: src=/usr/src/finance/index.html dest=/opt/finance/
  ```
---
## Ansible File Module

+ The Nautilus DevOps team is working to test several Ansible modules on servers in Stratos DC. Recently they wanted to test the file creation on remote hosts using Ansible. Find below more details about the task:
+ a. Create an inventory file ~/playbook/inventory on jump host and add all app servers in it.
+ b. Create a playbook ~/playbook/playbook.yml to create a blank file /tmp/data.txt on all app servers.
+ c. The /tmp/data.txt file permission must be 0755.
+ d. The user/group owner of file /tmp/data.txt must be tony on app server 1, steve on app server 2 and banner on app server 3.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml, so please make sure the playbook works this way without passing any extra arguments.

###### Solution

+ ```shell
  cd playbook
  ansible --version
  echo "stapp01 ansible_user=tony ansible_password=Ir0nM@n" > inventory
  echo "stapp02 ansible_user=steve ansible_password=Am3ric@" >> inventory
  echo "stapp03 ansible_user=banner ansible_password=BigGr33n" >> inventory
  ansible all -i inventory  -m ping
  vi playbook.yml
  ansible-playbook -i inventory playbook.yml
  #verify
  ansible all -i inventory  -a "ls -l /tmp/data.txt"
  ```
+ ```yaml
  ---
  - hosts: all
    tasks:
      - file:
          path: /tmp/data.txt
          state: touch
          owner: tony
          group: tony
          mode: '0755'
        when: ansible_hostname == "stapp01"
      - file:
          path: /tmp/data.txt
          state: touch
          owner: steve
          group: steve
          mode: '0755'
        when: ansible_hostname == "stapp02"
      - file:
          path: /tmp/data.txt
          state: touch
          owner: banner
          group: banner
          mode: '0755'
        when: ansible_hostname == "stapp03"
  ```
---
## Ansible Ping Module Usage

+ The Nautilus DevOps team is planning to test several Ansible playbooks on different app servers in Stratos DC. Before that, some pre-requisites must be met. Essentially, the team needs to set up a password-less SSH connection between Ansible controller and Ansible managed nodes. One of the tickets is assigned to you; please complete the task as per details mentioned below:
+ a. Jump host is our Ansible controller, and we are going to run Ansible playbooks through thor user on jump host.
+ b.Make appropriate changes on jump host so that user thor on jump host can SSH into App Server 1 through its respective sudo user. (for example tony for app server 1).
+ c. There is an inventory file /home/thor/ansible/inventory on jump host. Using that inventory file test Ansible ping from jump host to App Server 1, make sure ping works.

###### Solution
+ ```Shell
  ssh-keygen
  ssh-copy-id <user>@<hostname>
  ansible all -i ansible/inventory -m ping
  ansible all -i ansible/inventory -a "id"
  ```
---

## Ansible Install Package

+ The Nautilus Application development team wanted to test some applications on app servers in Stratos Datacenter.
+ They shared some pre-requisites with the DevOps team, and packages need to be installed on app servers. Since we are already using Ansible for automating such tasks, please perform this task using Ansible as per details mentioned below:
+ Create an inventory file /home/thor/playbook/inventory on jump host and add all app servers in it.
+ Create an Ansible playbook /home/thor/playbook/playbook.yml to install zip package on all app servers using Ansible yum module.
+ Make sure user thor should be able to run the playbook on jump host.
+ Note: Validation will try to run playbook using command ansible-playbook -i inventory playbook.yml so please make sure playbook works this way, without passing any extra arguments.

###### Solution

+ ```shell
  cd playbook
  ansible --version
  echo "stapp01 ansible_user=tony ansible_password=Ir0nM@n" > inventory
  echo "stapp02 ansible_user=steve ansible_password=Am3ric@" >> inventory
  echo "stapp03 ansible_user=banner ansible_password=BigGr33n" >> inventory
  ansible all -i inventory  -m ping
  vi playbook.yml
  ansible-playbook -i inventory playbook.yml
  #verify
  ansible all -i inventory  -a "zip --help"
  ```
+ ```yaml
  ---
  - hosts: all
    become: yes
    tasks:
      - yum: name=zip state=installed
  ```
---
## Ansible Archive Module

+ The Nautilus DevOps team has some data on each app server in Stratos DC that they want to copy to a different location. However, they want to create an archive of the data first, then they want to copy the same to a different location on the respective app server. Additionally, there are some specific requirements for each server. Perform the task using Ansible playbook as per requirements mentioned below:
+ Create a playbook named playbook.yml under /home/thor/ansible directory on jump host, an inventory file is already placed under /home/thor/ansible/ directory on Jump Server itself.
+ Create an archive beta.tar.gz (make sure archive format is tar.gz) of /usr/src/finance/ directory ( present on each app server ) and copy it to /opt/finance/ directory on all app servers. The user and group owner of archive beta.tar.gz should be tony for App Server 1, steve for App Server 2 and banner for App Server 3.
+ Note: Validation will try to run playbook using command ansible-playbook -i inventory playbook.yml so please make sure playbook works this way, without passing any extra arguments.
  
###### Solution

+ ```Shell
  cd ansible/
  vi playbook.yml
  ansible-playbook -i inventory playbook.yml
  ansible all -i inventory -a "ls -l /opt/finance"
  ```
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      -  archive:
          path: /usr/src/finance/
          dest: /opt/finance/beta.tar.gz
          format: gz
      - file: 
          path: /opt/finance/beta.tar.gz
          owner: tony
          group: tony
        when: ansible_hostname == "stapp01"
      - file:
          path: /opt/finance/beta.tar.gz
          owner: steve
          group: steve
        when: ansible_hostname == "stapp02"
      - file:
          path: /opt/finance/beta.tar.gz
          owner: banner
          group: banner
        when: ansible_hostname == "stapp03"
  ``` 
---
## Ansible Blockinfile Module

+ The Nautilus DevOps team wants to install and set up a simple httpd web server on all app servers in Stratos DC. + Additionally, they want to deploy a sample web page for now using Ansible only. Therefore, write the required playbook to complete this task. Find more details about the task below.
+ We already have an inventory file under /home/thor/ansible directory on jump host. Create a playbook.yml under /home/thor/ansible directory on jump host itself.
+ Using the playbook, install httpd web server on all app servers. Additionally, make sure its service should up and running.
+ Using blockinfile Ansible module add some content in /var/www/html/index.html file. Below is the content:
    "Welcome to XfusionCorp!
    This is Nautilus sample file, created using Ansible!
    Please do not modify this file manually!"
+ The /var/www/html/index.html file's user and group owner should be apache on all app servers.
+ The /var/www/html/index.html file's permissions should be 0644 on all app servers.
+ Note:
  + i. Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way without passing any extra arguments.
  + ii. Do not use any custom or empty marker for blockinfile module.

###### Solution
+ ```shell
  vi ansible/playbook.yml
  ansible-doc blockinfile
  ansible-playbook --syntax-check ansible/playbook
  ansible-playbook -i ansible/inventory ansible/playbook.yml
  ansible -i ansible/inventory -a "ls -l /var/www/html"
  for i in {1..3}; do curl stapp0$i:80; done
  ```
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - package: 
          name: httpd 
          state: installed
      - service: 
          name: httpd 
          state: started 
          enabled: yes
      - file:
          path: /var/www/html/index.html
          owner: apache
          group: apache
          mode: '0644'
          state: touch
      - blockinfile: 
          path: /var/www/html/index.html 
          block: |
            Welcome to XfusionCorp!
            This is Nautilus sample file, created using Ansible!
            Please do not modify this file manually!    
  ```
---
## Creating Soft Links Using Ansible

+ The Nautilus DevOps team is practicing some of the Ansible modules and creating and testing different Ansible playbooks to accomplish tasks. Recently they started testing an Ansible file module to create soft links on all app servers. Below you can find more details about it.
+ Write a playbook.yml under /home/thor/ansible directory on jump host, an inventory file is already present under /home/thor/ansible directory on jump host itself. Using this playbook accomplish below given tasks:
+ Create an empty file /opt/sysops/blog.txt on app server 1; its user owner and group owner should be tony. Create a symbolic link of source path /opt/sysops to destination /var/www/html.
+ Create an empty file /opt/sysops/story.txt on app server 2; its user owner and group owner should be steve. Create a symbolic link of source path /opt/sysops to destination /var/www/html.
+ Create an empty file /opt/sysops/media.txt on app server 3; its user owner and group owner should be banner. Create a symbolic link of source path /opt/sysops to destination /var/www/html.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure playbook works this way without passing any extra arguments.

###### Solution

+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - file: 
          path: /opt/sysops/blog.txt
          state: touch
          owner: tony
          group: tony
        when: ansible_hostname == "stapp01"
      - file: 
          path: /opt/sysops/story.txt 
          state: touch
          owner: steve
          group: steve
        when: ansible_hostname == "stapp02"
      - file: 
          path: /opt/sysops/media.txt 
          state: touch
          owner: banner
          group: banner
        when: ansible_hostname == "stapp03"
      - file:
          src: /opt/sysops/
          dest: /var/www/html
          state: link
  ```
---
## Managing ACLs Using Ansible

+ There are some files that need to be created on all app servers in Stratos DC. The Nautilus DevOps team want these files to be owned by user root only however, they also want that the app specific user to have a set of permissions on these files. All tasks must be done using Ansible only, so they need to create a playbook. Below you can find more information about the task.
+ Create a playbook named playbook.yml under /home/thor/ansible directory on jump host, an inventory file is already present under /home/thor/ansible directory on Jump Server itself.
+ Create an empty file blog.txt under /opt/devops/ directory on app server 1. Set some acl properties for this file. Using acl provide read '(r)' permissions to group tony (i.e entity is tony and etype is group).
+ Create an empty file story.txt under /opt/devops/ directory on app server 2. Set some acl properties for this file. Using acl provide read + write '(rw)' permissions to user steve (i.e entity is steve and etype is user).
+ Create an empty file media.txt under /opt/devops/ on app server 3. Set some acl properties for this file. Using acl provide read + write '(rw)' permissions to group banner (i.e entity is banner and etype is group).
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way, without passing any extra arguments.

###### Solution
+ ```shell
  cd ansible
  ansibe-doc file
  ansible-doc acl
  ansible-playbook -i inventory -C playbook.yml 
  ansible-playbook -i inventory playbook.yml
  ansible stapp01 -i inventory -a "getfacl /opt/devops/blog.txt"
  ```
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - block:
          - file:
              path: /opt/devops/blog.txt
              state: touch
          - acl:
              path: /opt/devops/blog.txt
              entity: tony
              etype: group
              permissions: r
              state: present
        when: ansible_hostname == "stapp01"
      - block:
          - file:
              path: /opt/devops/story.txt
              state: touch
          - acl:
              path: /opt/devops/story.txt
              entity: steve
              etype: user
              permissions: rw
              state: present
        when: ansible_hostname == "stapp02"
      - block:
          - file:
              path: /opt/devops/media.txt
              state: touch
          - acl:
              path: /opt/devops/media.txt
              entity: banner
              etype: group
              permissions: rw
              state: present
        when: ansible_hostname == "stapp03"
  ```
---
## Ansible Manage Services

+ Developers are looking for dependencies to be installed and run on Nautilus app servers in Stratos DC. They have shared some requirements with the DevOps team. Because we are now managing packages installation and services management using Ansible, some playbooks need to be created and tested. As per details mentioned below please complete the task:
+ a. On jump host create an Ansible playbook /home/thor/ansible/playbook.yml and configure it to install httpd on all app servers.
+ b. After installation make sure to start and enable httpd service on all app servers.
+ c. The inventory /home/thor/ansible/inventory is already there on jump host.
+ d. Make sure user thor should be able to run the playbook on jump host.
+ Note: Validation will try to run playbook using command ansible-playbook -i inventory playbook.yml so please make sure playbook works this way, without passing any extra arguments.

###### Solution
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - package: name=httpd state=installed
      - service: name=httpd state=started enabled=yes
  ```
---
## Ansible Lineinfile Module

+ The Nautilus DevOps team want to install and set up a simple httpd web server on all app servers in Stratos DC. They also want to deploy a sample web page using Ansible. Therefore, write the required playbook to complete this task as per details mentioned below.
+ We already have an inventory file under /home/thor/ansible directory on jump host. Write a playbook playbook.yml under /home/thor/ansible directory on jump host itself. Using the playbook perform below given tasks:
+ Install httpd web server on all app servers, and make sure its service is up and running.
+ Create a file /var/www/html/index.html with content:

>This is a Nautilus sample file, created using Ansible!

+ Using lineinfile Ansible module add some more content in /var/www/html/index.html file. Below is the content:

> Welcome to xFusionCorp Industries!

+ Also make sure this new line is added at the top of the file.
+ The /var/www/html/index.html file's user and group owner should be apache on all app servers.
+ The /var/www/html/index.html file's permissions should be 0644 on all app servers.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way without passing any extra arguments.

###### Solution
+ ```shell
  vi ansible/playbook.yml
  ansible-playbook -i ansible/inventory ansible/playbook.yml --syntax-check
  ansible-playbook -i ansible/inventory ansible/playbook.yml 
  ansible all -i ansible/inventory -a "ls -l /var/www/html/index.html" &&
  ansible all -i ansible/inventory -a "cat /var/www/html/index.html"
  ```
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - yum: name=httpd state=installed
      - service: name=httpd state=started enabled=true
      - copy: content="This is a Nautilus sample file, created using Ansible!" dest=/var/www/html/index.html owner=apache group="apache" mode='0655'
      - lineinfile: path=/var/www/html/index.html line="Welcome to Nautilus Group!" insertbefore=BOF
  ```
---
## Ansible Replace Module

+ There is some data on all app servers in Stratos DC. The Nautilus development team shared some requirement with the DevOps team to alter some of the data as per recent changes they made. The DevOps team is working to prepare an Ansible playbook to accomplish the same. Below you can find more details about the task.
+ Write a playbook.yml under /home/thor/ansible on jump host, an inventory is already present under /home/thor/ansible directory on Jump host itself. Perform below given tasks using this playbook:
+ We have a file /opt/sysops/blog.txt on app server 1. Using Ansible replace module replace string xFusionCorp to Nautilus in that file.
+ We have a file /opt/sysops/story.txt on app server 2. Using Ansiblereplace module replace the string Nautilus to KodeKloud in that file.
+ We have a file /opt/sysops/media.txt on app server 3. Using Ansible replace module replace string KodeKloud to xFusionCorp Industries in that file.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way without passing any extra arguments.

+ ```yaml
  ---
  - hosts: all
    tasks:
      - replace: path=/opt/sysops/blog.txt regexp='xFusionCorp' replace='Nautilus'
        when: ansible_hostname=="stapp01"
      - replace: path=/opt/sysops/story.txt regexp='Nautilus' replace='KodeKloud'
        when: ansible_hostname=="stapp02"
      - replace: path=/opt/sysops/media.txt regexp='KodeKloud' replace='xFusionCorp Industries'
        when: ansible_hostname=="stapp03"
  ```
---
## Ansible Create Users and Groups

+ Several new developers and DevOps engineers just joined the xFusionCorp industries. They have been assigned the Nautilus project, and as per the onboarding process we need to create user accounts for new joinees on at least one of the app servers in Stratos DC. We also need to create groups and make new users members of those groups. We need to accomplish this task using Ansible. Below you can find more information about the task.
+ There is already an inventory file ~/playbooks/inventory on jump host.
+ On jump host itself there is a list of users in ~/playbooks/data/users.yml file and there are two groups — admins and developers —that have list of different users. Create a playbook ~/playbooks/add_users.yml on jump host to perform the following tasks on app server 3 in Stratos DC.
+ a. Add all users given in the users.yml file on app server 3.
+ b. Also add developers and admins groups on the same server.
+ c. As per the list given in the users.yml file, make each user member of the respective group they are listed under.
+ d. Make sure home directory for all of the users under developers group is /var/www (not the default i.e /var/www/{USER}). Users under admins group should use the default home directory (i.e /home/devid for user devid).
+ e. Set password TmPcZjtRQx for all of the users under developers group and YchZHRcLkL for of the users under admins group. Make sure to use the password given in the ~/playbooks/secrets/vault.txt file as Ansible vault password to encrypt the original password strings. You can use ~/playbooks/secrets/vault.txt file as a vault secret file while running the playbook (make necessary changes in ~/playbooks/ansible.cfg file).
+ f. All users under admins group must be added as sudo users. To do so, simply make them member of the wheel group as well.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory add_users.yml so please make sure playbook works this way, without passing any extra arguments.

###### Solution
+ ```shell
  cd playbooks
  vi add_users.yml
  echo "vault_password_file=./secrets/vault.txt" >> ansibe.cfg
  ansible-vault encrypt add_users.yml
  cat add_users.yml
  ansible-playbook -i inventory add_users.yml
  ansible stapp03 -i inventory -m shell -a "id joy;id ray;cat /etc/passwd"
  #for further verification, you can ssh to the stapp03.
  ```
+ ```yaml
  ---
  - hosts: stapp03
    become: true
    vars_files:
      - ./data/users.yml
    vars:
      - password_admin: YchZHRcLkL
      - password_dev: TmPcZjtRQx
    tasks:
      - group: 
          name: admins 
          state: present
      - group: 
          name: developers 
          state: present
      - user: 
          name: "{{ item }}" 
          groups: admins,wheel 
          password: "{{ password_admin | password_hash('sha512') }}"
          state: present
        loop: "{{admins}}"
      - user: 
          name: "{{ item }}" 
          password: "{{ password_dev | password_hash('sha512') }}"
          state: present 
          groups: developers,wheel
          home: "/var/www/{{ item }}"
        loop: "{{ developers }}"
  ```
---
## Managing Jinja2 Templates Using Ansible:

+ One of the Nautilus DevOps team members is working on to develop a role for httpd installation and configuration. Work is almost completed, however there is a requirement to add a jinja2 template for index.html file. Additionally, the relevant task needs to be added inside the role. The inventory file ~/ansible/inventory is already present on jump host that can be used. Complete the task as per details mentioned below:
+ a. Update ~/ansible/playbook.yml playbook to run the httpd role on App Server 3.
+ b. Create a jinja2 template index.html.j2 under /home/thor/ansible/role/httpd/templates/ directory and add a line This file was created using Ansible on <respective server> (for example This file was created using Ansible on stapp01 in case of App Server 1). Also please make sure not to hard code the server name inside the template. Instead, use inventory_hostname variable to fetch the correct value.
+ c. Add a task inside /home/thor/ansible/role/httpd/tasks/main.yml to copy this template on App Server 3 under /var/www/html/index.html. Also make sure that /var/www/html/index.html file's permissions are 0644.
+ d. The user/group owner of /var/www/html/index.html file must be respective sudo user of the server (for example tony in case of stapp01).
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml so please make sure the playbook works this way without passing any extra arguments

###### Solution:
+ ```shell
  cd ansible
  vi playbook.yml #add the desired stapp server on the "hosts" header
  echo "This file was created using Ansible on {{ inventory_hostname }}" > /role/httpd/templates/index.html.j2
  vi /role/httpd/tasks/main.yml
  ansible-playbook -i inventory playbook.yml
  curl stapp03:80
    > This file was created using Ansible on stapp03
  ```
+ ```yaml
  #...exisiting tasks
  - template:
      src: index.html.j2
      dest: /var/www/html/index.html
      mode: '0644'
      group: banner
      owner: banner
    when: ansible_hostname == "stapp03"
  - template:
      src: index.html.j2
      dest: /var/www/index.html
      mode: '0644'
      group: steve
      owner: steve
    when: ansible_hostname == "stapp02"
  - template:
      src: index.html.j2
      dest: /var/www/index.html
      mode: '0644'
      group: tony
      owner: tony
    when: ansible_hostname == "stapp01"
  ```
---
## Ansible Setup Httpd and PHP

+ Nautilus Application development team wants to test the Apache and PHP setup on one of the app servers in Stratos Datacenter. They want the DevOps team to prepare an Ansible playbook to accomplish this task. Below you can find more details about the task.
+ There is an inventory file ~/playbooks/inventory on jump host.
+ Create a playbook ~/playbooks/httpd.yml on jump host and perform the following tasks on App Server 3.
+ a. Install httpd and php packages (whatever default version is available in yum repo).
+ b. Change default document root of Apache to /var/www/html/myroot in default Apache config /etc/httpd/conf/httpd.conf. Make sure /var/www/html/myroot path exists (if not please create the same).
+ c. There is a template ~/playbooks/templates/phpinfo.php.j2 on jump host. Copy this template to the Apache document root you created as phpinfo.php file and make sure user owner and the group owner for this file is apache user.
+ d. Start and enable httpd service.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory httpd.yml, so please make sure the playbook works this way without passing any extra arguments.

+ ```yaml
  ---
  - hosts: stapp03
    become: true
    tasks:
      - yum:
          name:
            - httpd
            - php
          state: installed
      - file:
          path: /var/www/html/myroot
          state: directory
          recurse: true
      - lineinfile:
          path: /etc/httpd/conf/httpd.conf
          regex: '^DocumentRoot "/var/www/html"'
          line: 'DocumentRoot "/var/www/html/myroot"'
      - template: 
          src: templates/phpinfo.php.j2
          dest: /var/www/html/myroot/phpinfo.php
          owner: apache
          group: apache
      - service:
          name: httpd
          state: started
          enabled: true
  ```
---
## Using Ansible Conditionals

+ The Nautilus DevOps team had a discussion about, how they can train different team members to use Ansible for different automation tasks. There are numerous ways to perform a particular task using Ansible, but we want to utilize each aspect that Ansible offers. The team wants to utilise Ansible's conditionals to perform the following task:
+ An inventory file is already placed under /home/thor/ansible directory on jump host, with all the Stratos DC app servers included.
+ Create a playbook /home/thor/ansible/playbook.yml and make sure to use Ansible's when conditionals statements to perform the below given tasks.
+ Copy blog.txt file present under /usr/src/finance directory on jump host to App Server 1 under /opt/finance directory. Its user and group owner must be user tony and its permissions must be 0755 .
+ Copy story.txt file present under /usr/src/finance directory on jump host to App Server 2 under /opt/finance directory. Its user and group owner must be user steve and its permissions must be 0755 .
+ Copy media.txt file present under /usr/src/finance directory on jump host to App Server 3 under /opt/finance directory. Its user and group owner must be user banner and its permissions must be 0755.
+ NOTE: You can use ansible_nodename variable from gathered facts with when condition. Additionally, please make sure you are running the play for all hosts i.e use - hosts: all.
+ Note: Validation will try to run the playbook using command ansible-playbook -i inventory playbook.yml, so please make sure the playbook works this way without passing any extra arguments
  
+ ```yaml
  ---
  - hosts: all
    become: true
    tasks:
      - copy:
          src: /usr/src/finance/blog.txt
          dest: /opt/finance/
          owner: tony
          group: tony
          mode: '0755'
        when: ansible_hostname == "stapp01"
      - copy:
          src: /usr/src/finance/story.txt
          dest: /opt/finance/
          owner: steve
          group: steve
          mode: '0755'
        when: ansible_hostname == "stapp02"
      - copy:
          src: /usr/src/finance/media.txt
          dest: /opt/finance/
          owner: banner
          group: banner
          mode: '0755'
        when: ansible_hostname == "stapp03"
  ```
> DONE...!