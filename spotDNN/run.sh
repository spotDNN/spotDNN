#!/bin/bash
line=$(cat launcher/instancesInfo.txt | head -n 1)
hosts=($line)
line=$(cat launcher/instancesInfo.txt | tail -n +2 | head -n 1)
hosts_private=($line)
line=$(cat launcher/instancesInfo.txt | tail -n +3 | head -n 1)
batchsize=($line)

placement=('0' '0')
basebatch=256
mode=0
maximgs=$1

declare -a lr_adjust
for (( i=0; i<${#batchsize[@]}; i++))
    do
    lr_adjust[$i]=$(echo "scale=4; ${batchsize[$i]} / $basebatch" | bc)
    done

func_train()
{
    declare -a info
    role_name=("ps" "worker")
    i=0
    for place in "${placement[@]}"
    do
        indexs=($place)
        j=0
        for index in "${indexs[@]}"
        do
            info[${index}]="${info[${index}]} ${role_name[${i}]}"
            let j+=1
        done
    let i+=1
    done

    for (( i=0; i<${#hosts[@]}; i++))
    do
    info[$i]="Host ${i} INFO: pubic IP address: ${hosts[i]}, private  IP address: ${hosts_private[i]} ... Role: ${info[${i}]}"
    echo ${info[$i]}
    done

    echo ""

    role_hosts=()
    i=0
    for place in "${placement[@]}"
    do
        indexs=($place)
        tmp=""
        for index in "${indexs[@]}"
        do
            let port=5555+i
            host=${hosts_private[$index]}:${port}
            if [ ${#tmp} -eq 0 ];then
                tmp=$host
            else
                tmp="$tmp,$host"
            fi
            let i+=1
        done
        role_hosts[${#role_hosts[@]}]=$tmp
    done

    sleep 15

    echo "###########################################################"
    echo "####################  start running  ######################"
    echo "###########################################################"


    file="resnet_ASP_img.py"
    run_para_str="--max_imgs=${maximgs}"

    i=0
    task=("ps" "worker")
    for place in "${placement[@]}"
    do
        indexs=($place)
        j=0
        for index in "${indexs[@]}"
        do
            host=${hosts[$index]}
            echo "host: ${host} start ${task[$i]}"   
            command=" python ./cifar_resnet_tf1/${file} \
                                    --TF_FORCE_GPU_ALLOW_GROWTH=true \
                                    --dataset=cifar100 \
                                    --resnet_size=110 \
                                    --batch_size=${batchsize[$j]} \
                                    --lr_adjust=${lr_adjust[$j]} \
                                    ${run_para_str} \
                                    --job_name=${task[$i]} \
                                    --task_index=${j} \
                                    --ps_hosts=${role_hosts[0]} \
                                    --worker_hosts=${role_hosts[1]} \
                                    --num_gpus=${#indexs[@]} "
            echo $command
            echo ""

            worker_place=(${placement[1]})
            let ps_wait=${#worker_place[@]}*6

            if [ $i -eq 0 ];then
            ssh -i tf-faye.pem ubuntu@${host} "sleep ${ps_wait} && ${command}" &
            else
            ssh -i tf-faye.pem ubuntu@${host} "${command}" &
            fi

        let j+=1
        done
        role_hosts[${#role_hosts[@]}]=$tmp
        let i+=1
    done

}

func_train