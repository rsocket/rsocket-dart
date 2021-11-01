format:
   dart format lib test

server:
   rsocket-cli -i "pong" --server --debug tcp://localhost:42252

request:
    rsocket-cli --keepalive 300s  --request -i "ping" --debug tcp://localhost:42252

server-stream:
   rsocket-cli --debug -i=@/Users/linux_china/data/words --server tcp://localhost:42252

stream:
   rsocket-cli --keepalive 300s --stream -i "Word Up" --debug tcp://localhost:42252

