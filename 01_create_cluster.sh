export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i hosts 01_create_cluster.yml -u ec2-user --private-key=private_key.pem 
