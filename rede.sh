sudo su 

docker build -t ubuntu-firewall -f Dockerfile.firewall .

docker run -d --network rede ubuntu-firewall