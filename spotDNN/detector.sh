#!/bin/bash
# public ip
line=$(cat launcher/instancesInfo.txt | head -n 1)
hosts=($line)
line=$(cat launcher/instancesInfo.txt | tail -n +4 | head -n 1)
hosts_type=($line)
tokens=()
for host in "${hosts[@]}"
    do
    echo "Initializing Token For ${host} ..."
    gettokencmd="curl -s -X PUT \"http://169.254.169.254/latest/api/token\" -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\""
    token=$(ssh -i tf-faye.pem ubuntu@${host} ${gettokencmd})
    tokens+=($token)
    i=i+1
    done

while sleep 10; do
    for (( i=0; i<${#hosts[@]}; i++))
    do
        token=${tokens[i]}
        host=${hosts[i]}
        gethttpcodecmd="curl -H \"X-aws-ec2-metadata-token: $token\" -s -w %{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action"
        httpcode=$(ssh -i tf-faye.pem ubuntu@${host} ${gethttpcodecmd})
        if [[ "$httpcode" -eq 401 ]] ; then
            echo 'Refreshing Authentication Token..'
            gettokencmd="curl -s -X PUT \"http://169.254.169.254/latest/api/token\" -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\""
            freshtoken=$(ssh -i tf-faye.pem ubuntu@${host} ${gettokencmd})
            tokens[i]=freshtoken
        elif [[ "$httpcode" -eq 200 ]] ; then
            # Revocation Detected...
            echo "run predictor" 
            # get all loss logs and fit the loss function -> loss objectives
            # get time for now -> remaining time
        else
            echo 'Not Interrupted'
        fi
    done
    echo ""
done