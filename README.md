=======
UnrealIRCD alpine based
======

shared directory - ~/docker_shared/configs/ 

docker build -t ircd .

sudo docker run --restart=always -p6667:6667 -v ~/docker_shared/configs/unrealircd:/home/ircd/unrealircd/conf -d --name ircd ircd


