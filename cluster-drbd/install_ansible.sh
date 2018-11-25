sudo cp /tmp/ansible.repo /etc/yum.repos.d
sudo yum -y clean metadata
sudo yum -y makecache fast
sudo yum -y install yum-plugin-ovl
sudo yum -y install epel-release
sudo yum -y makecache fast
sudo yum -y install deltarpm
sudo yum -y groupinstall minimal
sudo yum -y update --security
sudo yum -y install ansible
sudo rm -f /tmp/ansible.repo
