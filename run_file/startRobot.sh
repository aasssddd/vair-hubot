 #!/bin/bash

FILE_NAME="hubot.pid"
DATE="$(date +%Y-%m-%d_%H-%M)"

if [ -f "$FILE_NAME" ]; then
    echo "[Fail] Robot is still running, you have to stop robot first"
else
    cd vair_robot
    nohup sh bin/hubot -a slack &> "/logs/hubot.log.$DATE"
    echo $! > ../hubot.pid
    echo "Robot is up and running"
fi
