#!/bin/bash

# set -x

until curl -Is ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT} | head -n 1 | grep "200" >/dev/null; do
  echo "Waiting for the server to be up before adding Node Sources ..."
  sleep 3
done

#Get the session id
echo "Getting the session id"
sessionid=$(curl -d "username=admin&password=${PWS_LOGIN_ADMIN_PASSWORD}" ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest/scheduler/login)

#Get the status code to verify if the local  node source with the given name exists
echo "Getting status code of the local node source"
status_code_local=$(curl -k --write-out '%{http_code}' --silent --output /dev/null --request GET ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest/rm/nodesource/configuration?nodeSourceName=${STATIC_NS_NAME} --header sessionid:$sessionid)

#Get the status code to verify if the dynamic node source with the given name exists
echo "Getting status code of the dynamic node source"
status_code_dynamic=$(curl -k --write-out '%{http_code}' --silent --output /dev/null --request GET ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest/rm/nodesource/configuration?nodeSourceName=${DYNAMIC_NS_NAME} --header sessionid:$sessionid)

#Verify if the k8s static node source already exists
if [ $status_code_local -ne 200 ]; then
  echo "Local node source does not exist"
  #Create a local k8s NS is enabled
  if [ ${STATIC_NS} == "true" ]; then
    echo "Creating local node source"
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} --createns ${STATIC_NS_NAME} -infrastructure org.ow2.proactive.resourcemanager.nodesource.infrastructure.DefaultInfrastructureManager -policy org.ow2.proactive.resourcemanager.nodesource.policy.StaticPolicy 'ALL' 'ALL'
  fi
else
  echo "Local node source already exists"
  if [ ${STATIC_NS} == "true" ]; then
    #Undeploy/Deploy to remove red nodes
    echo "Undeploy/Deploy NS"
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -udpns ${STATIC_NS_NAME}
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -dpns ${STATIC_NS_NAME}
  else
    #Static k8s NS is not required, we undeploy it
    echo "Undeploy NS"
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -udpns ${STATIC_NS_NAME}
  fi
fi

#Verify if the k8s dynamic node source already exists
if [ $status_code_dynamic -ne 200 ]; then
  echo "Dynamic node source does not exist"
  #Create a dynamic k8s NS is enabled
  if [ ${DYNAMIC_NS} == "true" ]; then
    echo "Creating dynamic node source"
    export JAVA_OPTS="-Dproactive-pamr.router.address=proactive-scheduler-service -Dproactive.communication.protocol=pamr"
    /opt/proactive/server/default/tools/proactive-create-cred -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -o /opt/proactive/server/default/config/authentication/admin.cred -R pamr://0
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} --createns ${DYNAMIC_NS_NAME} -infrastructure org.ow2.proactive.resourcemanager.nodesource.infrastructure.KubernetesInfrastructure /opt/proactive/server/kube.config ${DYNAMIC_NS_NAMESPACE} 120 30 1 ${DYNAMIC_NS_IMAGE} /opt/proactive/server/dynamic-node-deployment.yaml "proactive-scheduler-service" "${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest/node.jar" "-Dproactive.communication.protocol=pamr -Dproactive.useIPaddress=true -Dproactive.pamr.router.address=proactive-scheduler-service" 'mkdir -p /tmp/node ; cd /tmp/node ; nodeJarUrl=%nodeJarUrl% ; until [ -f node.jar ] && [ -f jre.tar.gz ]; do wget -nv --no-check-certificate %nodeJarUrl%; wget -nv --no-check-certificate ${nodeJarUrl%/*}/jre.tar.gz; done; tar -xzvf jre.tar.gz ; /tmp/node/jre/bin/java -jar node.jar -Dproactive.communication.protocol=%protocol% -Dpython.path=%jythonPath% -Dproactive.pamr.router.address=%rmHostname% -D%instanceIdNodeProperty%=%instanceId% -r %rmUrl% -s %nodeSourceName% %nodeNamingOption% -v %credentials% -w %numberOfNodesPerInstance% %additionalProperties%' 600000 -policy org.ow2.proactive.resourcemanager.nodesource.policy.DynamicPolicy 'ALL' 'ALL' ${DYNAMIC_NS_MIN_NODES} ${DYNAMIC_NS_MAX_NODES} 'pamr://0' /opt/proactive/server/default/config/authentication/admin.cred 3000 3 15000 1 'true' 'false' 1000 90000 'false' ''
  fi
else
  echo "Dynamic node source already exists"
  if [ ${DYNAMIC_NS} == "true" ]; then
    echo "Dynamic node source already exists: Remove NS"
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -r ${DYNAMIC_NS_NAME}
    sleep 5
    echo "Dynamic node source already exists: Creating a new dynamic node source"
    export JAVA_OPTS="-Dproactive-pamr.router.address=proactive-scheduler-service -Dproactive.communication.protocol=pamr"
    /opt/proactive/server/default/tools/proactive-create-cred -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -o /opt/proactive/server/default/config/authentication/admin.cred -R pamr://0
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} --createns ${DYNAMIC_NS_NAME} -infrastructure org.ow2.proactive.resourcemanager.nodesource.infrastructure.KubernetesInfrastructure /opt/proactive/server/kube.config ${DYNAMIC_NS_NAMESPACE} 120 30 1 ${DYNAMIC_NS_IMAGE} /opt/proactive/server/dynamic-node-deployment.yaml "proactive-scheduler-service" "${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest/node.jar" "-Dproactive.communication.protocol=pamr -Dproactive.useIPaddress=true -Dproactive.pamr.router.address=proactive-scheduler-service" 'mkdir -p /tmp/node ; cd /tmp/node ; nodeJarUrl=%nodeJarUrl% ; until [ -f node.jar ] && [ -f jre.tar.gz ]; do wget -nv --no-check-certificate %nodeJarUrl%; wget -nv --no-check-certificate ${nodeJarUrl%/*}/jre.tar.gz; done; tar -xzvf jre.tar.gz ; /tmp/node/jre/bin/java -jar node.jar -Dproactive.communication.protocol=%protocol% -Dpython.path=%jythonPath% -Dproactive.pamr.router.address=%rmHostname% -D%instanceIdNodeProperty%=%instanceId% -r %rmUrl% -s %nodeSourceName% %nodeNamingOption% -v %credentials% -w %numberOfNodesPerInstance% %additionalProperties%' 600000 -policy org.ow2.proactive.resourcemanager.nodesource.policy.DynamicPolicy 'ALL' 'ALL' ${DYNAMIC_NS_MIN_NODES} ${DYNAMIC_NS_MAX_NODES} 'pamr://0' /opt/proactive/server/default/config/authentication/admin.cred 3000 3 15000 1 'true' 'false' 1000 90000 'false' ''
  else
    #Dynamic k8s NS is not required, we remove it
    echo "Dynamic node source already exists: Remove NS"
    /opt/proactive/server/default/bin/proactive-client -k -u ${PWS_PROTOCOL}://proactive-scheduler-service-web:${PWS_PORT}/rest -l admin -p ${PWS_LOGIN_ADMIN_PASSWORD} -r ${DYNAMIC_NS_NAME}
  fi
fi
