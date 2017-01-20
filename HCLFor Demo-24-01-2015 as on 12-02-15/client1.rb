# chef_server_url 'https://10.112.154.132:443'


chef_server_url "https://chefserverdemo1cs.cloudapp.net"

#node_name "AD-Server"
validation_client_name "chef-validator"
validation_key "c:/chef/chef-validator.pem"
log_location "C:/chef/client.log"
cookbook_path "C:/chef-repo/"
