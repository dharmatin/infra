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
function health_check_old_tg {
  aws elbv2 describe-target-health --target-group-arn ${live_tg} --region ${aws_region} --query "TargetHealthDescriptions[].[TargetHealth.[State]]" --output text > ./health_check_old_inst_tg.txt
  aws elbv2 describe-target-health --target-group-arn ${ssl_live_tg} --region ${aws_region} --query "TargetHealthDescriptions[].[TargetHealth.[State]]" --output text >> ./health_check_old_inst_tg.txt
    cat ./health_check_old_inst_tg.txt | while read line ;
    do
      if [ "$line" == "healthy" ]; then
        echo "All stack are working"
        else
         echo -e "${RED}Stack ${RED}will ${RED}delete ${RED}the ${RED}latest ${RED}stack ${RED}here "
         exit 1
      fi
    done
}

delete_cf_stack () {
  echo "deleting stack  --->>>>   $1"
  aws cloudformation delete-stack --stack-name $1 --region ${aws_region}
}
list_env_stack ()
{
  aws cloudformation list-stacks --stack-status-filter CREATE_FAILED CREATE_COMPLETE ROLLBACK_FAILED ROLLBACK_COMPLETE DELETE_FAILED UPDATE_COMPLETE UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE --query "StackSummaries[*].[StackName]" --region ${aws_region}  --output text | grep -i "front-newlaunch-api-${deployment_env}*" > ./all_stack.txt
  cat ./all_stack.txt | while read line ;
    do
      if [ "$line" == "${new_stack_name}" ]; then
        echo "Skip it is new deployment ${new_stack_name} "
        else
         delete_cf_stack ${line}
      fi
    done
    rm ./all_stack.txt ./health_check_old_inst_tg.txt ./list_elb_target_group.txt ./list_elb_listener.txt
}
if [ $2 == "stag" ] && [ $1 == "arn:aws:elasticloadbalancing:ap-southeast-1:726150208279:loadbalancer/app/newlaunch-api-id-alb-stag/413a99f4de2a5086" ]; then
 echo -e " env is stag "
else
 exit 1
fi


list_elb_listener
live_listener
ssl_live_listener
list_elb_target_group
live_targetgroup
ssl_live_targetgroup
health_check_old_tg
list_env_stack
