#!/bin/sh
# notice: the relase version number also is ansible version number. 
set -e
# show info message
showSuccessMessage(){
    echo -e "\033[32m$1\033[0m";
}

# show success message
showInfoMessage(){
     echo "######################################################################################"
     echo -e "\033[36m$1\033[0m"; 
}

# show start message
showStartMessage(){
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
     echo -e "\033[33mRelease start...\033[0m"; 
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
}

# show end message
showEndMessage(){
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
     echo -e "\033[33mrelease success! \033[0m"
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
	 echo "**************************************************************************************"
}

showStartMessage
# work path
workPath=$(cd `dirname $0`; pwd) 
# git account login name
gitLoginName="zhaoyi"
# git account password
gitPassword="sunrunvas"
# git japi url
gitJapi="http://$gitLoginName:$gitPassword@git.gzsunrun.cn/dfs/japi.git" 
# web ansible url
gitWeb="http://$gitLoginName:$gitPassword@git.gzsunrun.cn/dfs/dfs_web.git"
# git ansible url
gitAnsible="http://$gitLoginName:$gitPassword@git.gzsunrun.cn/dfs/dfs_ansible.git"

# get the release version number
showInfoMessage "Please enter the release version number："
read ver

# get the japi version number
showInfoMessage "Please enter the japi version number："
read verJapi

# get the web version number
showInfoMessage "Please enter the web version number："
read verWeb

# clone japi
showInfoMessage "Clone the japi of git repertory，version number is ver$ver..."
git clone -b 3.1.$verJapi $gitJapi --depth 1
showSuccessMessage "Clone japi success!"

# clone web
showInfoMessage "Clone the web of git repertory，version number is ver$ver..."
git clone -b 3.1.$verWeb $gitWeb sunrundfs --depth 1
showSuccessMessage "Clone web success!"

# clone ansible: notice the ansible version number is same to relase version number
showInfoMessage "Clone the web of ansible repertory，version number is ver$ver..."
git clone -b 3.1.$ver $gitAnsible --depth 1
showSuccessMessage "Clone ansible success!"

# package the web code...
showInfoMessage "Package the web..."
tar -cvf sunrundfs.tar.gz sunrundfs
mv -f sunrundfs.tar.gz $workPath/dfs_ansible/DFS3.1_Server/roles/dfs.web/files/sunrundfs.tar.gz
showSuccessMessage "Package web package success!"

# package the japi code...
showInfoMessage "Package the japi..."
cd japi
ant -Djdk.home=/usr/lib/jvm/java -Djre.home=/usr/lib/jvm/jre-1.8.0
mv -f japi.war $workPath/dfs_ansible/DFS3.1_Server/roles/dfs.japi/files/japi.war
showSuccessMessage "Package japi package success!"

# package the ansible...
showInfoMessage "Package the ansible..."
cd $workPath/dfs_ansible
tar -czvf $workPath/DFS3.1_Server_Build$ver.tar.gz DFS3.1_Server
showSuccessMessage "Package ansible package success!"

# changed to work path
cd $workPath

# delete japi
showInfoMessage "Delete folder japi..."
rm -rf japi
showSuccessMessage "Delete success!"

# delete web
showInfoMessage "Delete folder dfs_web..."
rm -rf sunrundfs
showSuccessMessage "Delete success!"

# delete dfs_ansible
showInfoMessage "Delete folder dfs_ansible..."
rm -rf dfs_ansible 
showSuccessMessage "Delete success!"

showEndMessage