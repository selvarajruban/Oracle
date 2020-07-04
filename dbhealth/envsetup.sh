Environment variables
###############################################################################

eval bart_home=~${RRP_USERNAME:-rrp_user}

if [ "$COMPONENT_TYPE" = "BART" ]
then
	. $bart_home/rrp_env_posix /${COMPONENT_TYPE}${COMPONENT_NNI}/config/rrp_environment
else
	. $bart_home/rrp_env_posix /mca/config/rrp_environment
fi

