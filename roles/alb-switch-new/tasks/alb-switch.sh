#!/usr/bin/env bash
set -eux

RED='\033[0;31m'

load_balancer_arn=$1
deployment_env=$2
aws_region=$3
new_stack_name=$4

function list_elb_listener {
  aws elbv2 describe-listeners --load-balancer-arn ${load_balancer_arn}  --query "Listeners[].[Port,ListenerArn]" --region ${aws_region}  --output text  > list_elb_listener.txt
}
function live_listener {
  live_list=`awk '{print $1,$2}' ./list_elb_listener.txt | awk '/^80/{print}' | awk '{print $2}'`
  echo "80 port is map to  ${live_list}"
}
function ssl_live_listener {
  ssl_live_list=`awk '{print $1,$2}' ./list_elb_listener.txt | awk '/^443/{print}' | awk '{print $2}'`
  echo "443 port is map to  ${ssl_live_list}"
}
function new_listener {
  new_list=`awk  '{print $1,$2}' ./list_elb_listener.txt | awk '/^81/{print}' | awk '{print $2}'`
  echo  " 81 port is map to ${new_list}"
}
function list_elb_target_group {
  aws elbv2 describe-listeners --load-balancer-arn ${load_balancer_arn}  --query "Listeners[].[DefaultActions[].TargetGroupArn, Port]" --region ${aws_region}  --output text | sed 'N;s/\n/ /' > list_elb_target_group.txt
}
function live_targetgroup {
  live_tg=`awk '{print $1,$2}' ./list_elb_target_group.txt | awk '/^80/{print}' | awk '{print $2}'`
  echo "80 port is map to  ${live_tg}"
}
function ssl_live_targetgroup {
  ssl_live_tg=`awk '{print $1,$2}' ./list_elb_target_group.txt | awk '/^443/{print}' | awk '{print $2}'`
  echo "443 port is map to  ${ssl_live_tg}"
}
function new_targetgroup {
  new_tg=`awk  '{print $1,$2}' ./list_elb_target_group.txt | awk '/^81/{print}' | awk '{print $2}'`
  echo  " 81 port is map to ${new_tg}"
}
function health_check_new_tg {
  aws elbv2 describe-target-health --target-group-arn ${new_tg} --region ${aws_region} --query "TargetHealthDescriptions[].[TargetHealth.[State]]" --output text > ./health_check_new_inst_tg.txt
    cat ./health_check_new_inst_tg.txt | while read line ;
    do
      if [ "$line" == "healthy" ]; then
        echo "All stack are working"
        else
         echo -e "${RED}Stack ${RED}will ${RED}delete ${RED}the ${RED}latest ${RED}stack ${RED}here "
         echo -e "Something need to do here"
         exit 1
      fi
    done
}
function health_check_old_tg {
  aws elbv2 describe-target-health --target-group-arn ${live_tg} --region ${aws_region} --query "TargetHealthDescriptions[].[TargetHealth.[State]]" --output text > ./health_check_old_inst_tg.txt
  aws elbv2 describe-target-health --target-group-arn ${ssl_live_tg} --region ${aws_region} --query "TargetHealthDescriptions[].[TargetHealth.[State]]" --output text >> ./health_check_old_inst_tg.txt
    cat ./health_check_old_inst_tg.txt | while read line ;
    do
      if [ "$line" == "healthy" ]; then
        echo "All stack are working"
        else
         echo -e "${RED}Stack ${RED}will ${RED}delete ${RED}the ${RED}latest ${RED}stack ${RED}here "
         echo -e "Something need to do here"
         exit 1
      fi
    done
}

function modify_listener {
  aws elbv2 modify-listener --listener-arn ${live_list} --default-actions Type=forward,TargetGroupArn=${new_tg} --region ${aws_region}
  aws elbv2 modify-listener --listener-arn ${ssl_live_list} --default-actions Type=forward,TargetGroupArn=${new_tg} --region ${aws_region}
  health_check_new_tg
  rm ./health_check_old_inst_tg.txt  ./health_check_new_inst_tg.txt ./list_elb_target_group.txt ./list_elb_listener.txt
}
function remove_listener {
  aws elbv2 delete-listener --listener-arn ${new_list} --region ${aws_region}
}
if [ $2 == "stag" ] && [ $1 == "arn:aws:elasticloadbalancing:ap-southeast-1:726150208279:loadbalancer/app/newlaunch-api-id-alb-stag/413a99f4de2a5086" ]; then
 echo -e " env is stag "
if [ $2 == "prod" ] && [ $1 == "arn:aws:elasticloadbalancing:ap-southeast-1:726150208279:loadbalancer/app/newlaunch-api-id-alb-prod/729ed6a0f9fb529f" ]; then
 echo -e " env is prod "
else
 exit 1
fi


list_elb_listener
live_listener
ssl_live_listener
new_listener
list_elb_target_group
live_targetgroup
ssl_live_targetgroup
new_targetgroup
health_check_new_tg
health_check_old_tg
modify_listener
remove_listener