# Ansible for deploying a FullCtl managed routeserver

For additional documentation visit https://docs.fullctl.com/ixctl/

## Configuration

For this example the basic required environment is shown, this should be customized and expanded upon as needed.

Define your host inventory in `prod/hosts`, this can be expanded to multiple inventories for per site.

Global shared env is defined in `group_vars/all.yaml`, the FULLCTL_* values should be secured in a vault.

```
---
FULLCTL_ORG: org
FULLCTL_IXP: org_ix
FULLCTL_API_KEY: xxx
```

Shared routeserver env is defined in `group_vars/rs.yaml`, at minimum you need to define a container version tag `rs_image_tag`

```
---
rs_image_registry: ghcr.io
rs_image_repo: fullctl/routeserver
rs_image_tag: 0.8.0-bird-2.14
```

Additionally each routeserver has its own env defined in `host_vars/<rs-host-name>.yaml`, this is used to store values such as heartbeat URLs, which should be stored as a vault.

```
---
vault_env:
  HEARTBEAT_URL_BIRD: "https://uptime.example.com/api/push/xxx"
  HEARTBEAT_URL_CONFIG: "https://uptime.example.com/api/push/xxx"
```


## Deploying a routeserver

Once the env above is configured you can simply deploy to one or more routeserver host with the following command

```
ansible-playbook -i prod/ site.yaml --limit=rs1
```

## Updating an existing deployment

When updating a routeserver, update `rs_image_tag` to the desired tag

Stop the currently running containers, disabling the service avoid needlessly flapping bird during an upgrade reboot

```
systemctl disable --now fullctl-birdrefresh.service
systemctl disable --now fullctl-routeserver.service
```

Upgrade host os, packages, and reboot as needed.

```
dnf update -y
reboot
```

Deploy new containers, identical to the first deployment

```
ansible-playbook -i prod/ site.yaml --limit=rs1
```

## Managing an existing deployment

For additional documentation visit https://docs.fullctl.com/ixctl/Route-Server-Management/

The route server is deployed via podman containers under the root user

Running `podman ps` as root should show two containers runnin, `fullctl_routeserver` for the bird instance itself and `fullctl_birdrefresh` for a process that manages the config synchronization.

```
fullctl_routeserver
fullctl_birdrefresh
```

Both containers are controlled by two systemd units and can be managed like any other service

```
systemctl status fullctl-routeserver.service
systemctl status fullctl-birdrefresh.service
```

stop bird completely

```
systemctl disable --now fullctl-routeserver.service
systemctl disable --now fullctl-birdrefresh.service

```

start bird completely

```
systemctl enable --now fullctl-routeserver.service
systemctl enable --now fullctl-birdrefresh.service
```

list sessions

```
podman exec -it fullctl_routeserver /srv/bird/sbin/birdc show protocols
```

bird logs to the system journal and to flat files that are periodically rotated.

```
tail -F /srv/fullctl/rs/bird/var/log/bird.log
```

the current bird config is also available outside the container at `/srv/fullctl/rs/bird/etc/bird.conf`
