#!/bin/sh

[[ -s /etc/default/evm ]] && source /etc/default/evm

# Source OpenShift scripting env
[[ -s ${CONTAINER_SCRIPTS_ROOT}/container-deploy-common.sh ]] && source "${CONTAINER_SCRIPTS_ROOT}/container-deploy-common.sh"

# Delay in seconds before we init, allows rest of services to settle
sleep "${APPLICATION_INIT_DELAY}"

# Prepare initialization environment
prepare_init_env

# Check deployment status
check_deployment_status

# Select path of action based on DEPLOYMENT_STATUS value
case "${DEPLOYMENT_STATUS}" in
  redeployment)
  echo "== Starting Re-deployment =="
  restore_pv_data
  setup_memcached
  migrate_db
  ;;
  upgrade)
  echo "== Starting Upgrade =="
  backup_pv_data
  run_hook pre-upgrade
  restore_pv_data
  setup_memcached
  migrate_db
  run_hook post-upgrade
  ;;
  new_deployment)
  echo "== Starting New Deployment =="
  # Setup logs on PV before init
  setup_logs

  # Setup memcached host in EVM configuration
  setup_memcached

  # Run appliance_console_cli to init appliance
  init_appliance

  # Sync persistent data from application rootdir on PV
  sync_pv_data

  # Restore symlinks from PV to application rootdir
  restore_pv_data

  # Write deployment info file to PV
  write_deployment_info
  ;;
  *)
  echo "Could not find a suitable deployment type, exiting.."
  exit 1
esac
