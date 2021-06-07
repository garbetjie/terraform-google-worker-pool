Terraform Module: Google Workers
================================

A Terraform module for the [Google Cloud Platform](https://cloud.google.com) that makes it easy to create and configure
a pool of instances that run multiple background processors in Docker containers.

# Table Of Contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Terminology](#terminology)
* [Usage](#usage)
  * [CloudSQL](#cloudsql)
  * [Timers](#timers)
  * [Argument escaping](#argument-escaping)
  * [Logging](#logging)
  * [Health checks](#health-checks)
  * [Exposing workers](#exposing-workers)
* [Inputs](#inputs)
* [Outputs](#outputs)
* [Roadmap](#roadmap)

# Introduction

Many systems require workers that process jobs in the background. Typically, these jobs are not time sensitive, and will
take longer to run that what is acceptable for most user interfaces. Examples of these kinds of workers include queue
processors, cron jobs and sending of emails.

This Terraform module makes it very simple & easy to create a
[Managed Instance Group](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) that is able to
run multiple workers per server. If any CloudSQL connections are required, a sidecar container is
automatically created that will manage the connections to the database, and provide them as UNIX sockets available
through a shared volume.

# Requirements

* Terraform >= 0.14
* [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest)

# Terminology

There are a few terms used throughout this module & documentation. The commonly-used terms are outlined below for full
clarity:

* **worker**
  
  A long-running process that handles and processes jobs.

* **timer**
  
  A process that is run on a pre-determined schedule. This is similar to a cronjob.

* **instance**
  
  A Google Compute Engine instance on which timers and workers are run.

* **pool**
  
  A group of instances that are part of a managed instance group.


# Usage

```terraform
module worker {
  source = "garbetjie/worker-pool/google"
  
  name = "my-pool"
  location = "europe-west4"
  disk_size = 25
  disk_type = "pd-balanced"
  instance_count = 1
  labels = { "my-label" = "my label value" }
  machine_type = "f1-micro"
  metadata = { "my-key" = "my metadata value" }
  network = "default"
  preemptible = false
  runcmd = ["touch /tmp/touched"]
  service_account_email = "serviceAccount@my-project-id.iam.gserviceaccount.com"
  tags = ["my-tag"]
  timezone = "Etc/UTC"
  wait_for_instances = false
  
  workers = {
    image = "nginx:latest"
    replicas = 1
    args = ["nginx"]
    env = { "ENV_KEY" = "value" }
    user = "root"
    expose = [{ port = 80, container_port = 80, host = "0.0.0.0", protocol = "tcp" }]
    mounts = [{ src = "my-data", target = "/www", type = "volume", readonly = true }]
    restart_policy = "always"
    restart_interval = 3
    pre = [{ args = ["mkdir", "-p", "/www/dir"], image = "alpine:latest", user = "root" }]
  }
  
  timers = [{
    schedule = "minutely"
    args = ["curl", "$${PROTOCOL}://example.org"]
    image = "alpine:latest"
    user = null
    env = { PROTOCOL = "https" }
    mounts = []
  }]
  
  logging = {
    driver = "local"
    options = {}
  }
  
  cloudsql = {
    connections = ["my-project-id:europe-west4:my-instance"]
    wait_duration = 30
    mount_name = "cloudsql"
    mount_path = "/cloudsql"
    restart_policy = "always"
    restart_interval = 3
  }
  
  health_check = {
    enabled = true
    port = 4144
    name = "my-pool-health-check"
    interval = 10
    healthy_threshold = 3
    unhealthy_threshold = 3
    initial_delay = 60
  }
}
```

## Inputs

| Name                             | Description                                                                                                                                                                           | Type                                                                                          | Default                 | Required |
|----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|-------------------------|----------|
| name                             | Name of the pool.                                                                                                                                                                     | string                                                                                        |                         | Yes      |
| location                         | Zone or region in which to create the pool.                                                                                                                                           | string                                                                                        |                         | Yes      |
| cloudsql                         | CloudSQL configuration.                                                                                                                                                               | object({ connections = set(string) })                                                         | `{ connections = [] }`  | No       |
| cloudsql.connections             | CloudSQL connections to establish before starting workers.                                                                                                                            | set(string)                                                                                   |                         | Yes      |
| cloudsql.wait_duration           | How long to wait (in seconds) for CloudSQL connections to be established before starting workers.                                                                                     | number                                                                                        | `30`                    | No       |
| cloudsql.mount_name              | Name of the volume created for mounting into workers.                                                                                                                                 | string                                                                                        | `"cloudsql"`            | No       |
| cloudsql.mount_path              | Path in the workers & timers to mount the volume containing CloudSQL connections.                                                                                                     | string                                                                                        | `"/cloudsql"`           | No       |
| cloudsql.restart_policy          | The restart policy to apply to the CloudSQL service. Must be one of \[`"always"`, `"no"`, `"on-success"`, `"on-failure"`, `"on-abnormal"`, `"on-watchdog"`, `"on-abort"`\].           | string                                                                                        | `"always"`              | No       |
| cloudsql.restart_interval        | Number of seconds to wait before restarting the CloudSQL service if it stops.                                                                                                         | number                                                                                        | `5`                     | No       |
| disk_size                        | Disk size (in GB) to create instances with.                                                                                                                                           | number                                                                                        | `25`                    | No       |
| disk_type                        | Disk type to create instances with. Must be one of \[`"pd-ssd"`, `"local-ssd"`, `"pd-balanced"`, `"pd-standard"`\].                                                                   | string                                                                                        | `"pd-balanced"`         | No       |
| health_check                     | Health check configuration.                                                                                                                                                           | object({ enabled = bool })                                                                    | `{ enabled = false }`   | No       |
| health_check.enabled             | Flag indicating whether the health check is enabled.                                                                                                                                  | bool                                                                                          |                         | Yes      |
| health_check.port                | Host port that is exposed for the health check.                                                                                                                                       | number                                                                                        | `4144`                  | No       |
| health_check.name                | Name to create the health check with.                                                                                                                                                 | string                                                                                        | `"${var.name}-healthy"` | No       |
| health_check.interval            | Interval between checks.                                                                                                                                                              | number                                                                                        | `10`                    | No       |
| health_check.healthy_threshold   | Number of consecutive health checks that must succeed for an instance to be marked as healthy.                                                                                        | number                                                                                        | `3`                     | No       |
| health_check.unhealthy_threshold | Number of consecutive health checks that must fail for an instance to be marked as unhealthy.                                                                                         | number                                                                                        | `3`                     | No       |
| health_check.initial_delay       | Number of seconds to allow instances to boot before starting health checks.                                                                                                           | number                                                                                        | `60`                    | No       |
| instance_count                   | Number of instances to create in the pool.                                                                                                                                            | number                                                                                        | `1`                     | No       |
| labels                           | [Labels](https://cloud.google.com/run/docs/configuring/labels) to apply to all instances in the pool.                                                                                 | map(string)                                                                                   | `{}`                    | No       |
| logging                          | Docker logging configuration.                                                                                                                                                         | object({ driver = string })                                                                   | `{ driver = "local" }`  | No       |
| logging.driver                   | Driver to use as default. See https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers for supported drivers.                                           | string                                                                                        |                         | Yes      |
| logging.options                  | Options to specify for the configured driver. See the [logging](#logging) section for default options per driver.                                                                     | map(string)                                                                                   | `{}`                    | No       |
| machine_type                     | Machine type to create instances in the pool with.                                                                                                                                    | string                                                                                        | `"f1-micro"`            | No       |
| metadata                         | Additional metadata to add to instances. Any metadata with the key `"user-data"` will be ignored.                                                                                     | map(string)                                                                                   | `{}`                    | No       |
| network                          | Network name or link in which to create the pool.                                                                                                                                     | string                                                                                        | `"default"`             | No       |
| preemptible                      | Whether or not to create [preemptible](https://cloud.google.com/compute/docs/instances/preemptible) instances.                                                                        | bool                                                                                          | `false`                 | No       |
| runcmd                           | Additional commands to run on instance startup. These commands are run after Docker is configured & restarted, and immediately before any workers & CloudSQL connections are started. | list(string)                                                                                  | `[]`                    | No       |
| service_account_email            | Service account to assign to the pool.                                                                                                                                                | string                                                                                        | `null`                  | No       |
| tags                             | Network tags to apply to instances in the pool.                                                                                                                                       | list(string)                                                                                  | `[]`                    | No       |
| timers                           | List of timers to run on a set schedule.                                                                                                                                              | list(object({ schedule = string }))                                                           | `[]`                    | No       |
| timers.*.schedule                | The schedule on which this timer should run. The [`OnCalendar`](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#OnCalendar=) format is used.                      | string                                                                                        |                         | Yes      |
| timers.*.args                    | Arguments to pass to the timer. See the notes about [argument escaping](#argument-escaping) for information on formatting.                                                            | list(string)                                                                                  | `[]`                    | No       |
| timers.*.image                   | Docker image on which the timer is based. Defaults to the same image as specified in `var.workers.image`.                                                                             | string                                                                                        | `var.workers.image`     | No       |
| timers.*.user                    | User under which to run the timer. Defaults to the same user as specified in `var.workers.user`.                                                                                      | string                                                                                        | `var.workers.user`      | No       |
| timers.*.env                     | Environment variables to inject into the timer. Defaults to those specified in `var.workers.env`.                                                                                     | map(string)                                                                                   | `var.workers.env`       | No       |
| timers.*.mounts                  | Volumes to mount into the timer container. Defaults to those specified in `var.workers.mounts`. See [Worker inputs](#worker-inputs) for full mount specification.                     | object({ src = string, target = string, type = optional(string), readonly = optional(bool) }) | `var.workers.mounts`    | No       |
| timezone                         | Timezone to use on instances. See the "TZ database name" column on https://en.wikipedia.org/wiki/List_of_tz_database_time_zones for an indication as to available timezone names.     | string                                                                                        | `"Etc/UTC"`             | No       |
| wait_for_instances               | Wait for instances to stabilise starting after updating the pool's instance group.                                                                                                    | bool                                                                                          | `false`                 | No       |
| workers                          | Worker configuration.                                                                                                                                                                 | object({ image = string, replicas = number })                                                 |                         | Yes      |
| workers.image                    | Docker image on which the workers are based.                                                                                                                                          | string                                                                                        |                         | Yes      |
| workers.replicas                 | Number of workers to start up per instance.                                                                                                                                           | number                                                                                        |                         | Yes      |
| workers.args                     | Arguments to pass to workers. See the section on [argument escaping](#argument-escaping) for line break support.                                                                      | list(string)                                                                                  | `[]`                    | No       |
| workers.env                      | Environment variables to inject into workers.                                                                                                                                         | map(string)                                                                                   | `{}`                    | No       |
| workers.user                     | User to run workers as. Passed unmodified to the `-u` flag when running workers.                                                                                                      | string                                                                                        | `null`                  | No       |
| workers.restart_policy           | Restart policy to apply to failed workers. Must be one of \[`always"`, `"no"`, `"on-success"`, `"on-failure"`, `"on-abnormal"`, `"on-watchdog"`, `"on-abort"`\].                      | string                                                                                        | `"always"`              | No       |
| workers.restart_interval         | Number of seconds to wait before restarting a failed worker.                                                                                                                          | number                                                                                        | `5`                     | No       |
| workers.expose                   | Container ports to expose on the host. Should not be used if `worker.replicas` > 1.                                                                                                   | list(object({ port = number, protocol = string, container_port = number, host = string}))     | `[]`                    | No       |
| workers.expose.*.port            | Port on the host to map to the container.                                                                                                                                             | number                                                                                        |                         | Yes      |
| workers.expose.*.container_port  | Port on the container to map to the host port. Defaults to `port` if not specified.                                                                                                   | number                                                                                        | `port`                  | No       |
| workers.expose.*.host            | The IP address on which to bind the port on the host.                                                                                                                                 | string                                                                                        | `"0.0.0.0"`             | No       |
| workers.expose.*.protocol        | The protocol with which the port listens. Can be one of `"tcp"` or `"udp"`.                                                                                                           | string                                                                                        | `"tcp"`                 | No       |
| workers.pre                      | Containers to execute immediately prior to starting up each worker. Can be used to prepare worker (changing permissions on directories, etc).                                         | list(object({ args = list(string), image = string, user = string }))                          | `[]`                    | No       |
| workers.pre.*.args               | Arguments to pass to the init container.See the section on [argument escaping](#argument-escaping) for line break support.                                                            | list(string)                                                                                  | `[]`                    | No       |
| workers.pre.*.image              | Docker image to run the init container with. Defaults to the value of `workers.image`.                                                                                                | string                                                                                        | `workers.image`         | No       |
| workers.pre.*.user               | User to run the init container as.                                                                                                                                                    | string                                                                                        | `null`                  | No       |
| workers.mounts                   | Volumes to mount into the worker containers.                                                                                                                                          | list(object({ src = string, target = string, type = string, readonly = bool }))               | `[]`                    | No       |
| workers.mounts.*.src             | Source to mount into the worker containers.                                                                                                                                           | string                                                                                        |                         | Yes      |
| workers.mounts.*.target          | Target path in the container to mount the volume or bind source.                                                                                                                      | string                                                                                        |                         | Yes      |
| workers.mounts.*.type            | Type of mount. Can be one of `"volume"` or `"bind"`.                                                                                                                                  | string                                                                                        | `"volume"`              | No       |
| workers.mounts.*.readonly        | Whether or not the mount is writable.                                                                                                                                                 | bool                                                                                          | `false`                 | No       |

## CloudSQL

When specifying at least one CloudSQL connection in the `var.cloudsql.connections` input attribute, an instance of the
[CloudSQL proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy) is started for you, and a volume containing configured
UNIX sockets is created. This makes it easy to create CloudSQL connections for your workers.

A `cloudsql.service` systemd unit is generated, and is added as a hard requirement to workers and timers - if the CloudSQL
service fails to start, no workers or timers will run. Additionally, a volume is automatically mounted into all workers
and timers at the directory specified by `var.cloudsql.mount_path` (defaulting to `/cloudsql`) containing the UNIX sockets
that can be used to connect to the specified CloudSQL instances.

> This requires the `roles/cloudsql.client` IAM role to be populated on the service account the instances run as.

> **Please note:** Only UNIX socket connections are currently supported. When `var.cloudsql.connections` is populated,
> there is a shell script that is run that forces workers and timers to wait until the connections have been established.
> This shell script only works with UNIX sockets at this point.

## Timers

Using timers in systemd is the way to schedule tasks that need to be run on a regular basis - systemd's implementation of
cron jobs. When specifying timers to be run, the following attributes will be inherited from the worker configuration if
not specified: `image`, `user`, `mounts`, and `env`.

> When specifying the schedule on which timers should run, it is the
> [`OnCalendar`](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#OnCalendar=) property that is populated.
> [This page](https://www.freedesktop.org/software/systemd/man/systemd.time.html#Calendar%20Events) contains more information
> on the allowed formats of this property.

## Argument escaping

Arguments passed in `var.workers.args` and `var.timers.*.args` are escaped, and can safely contain spaces, strings and
any number of values.

Using regular expressions to accomplish this task would be too complex and error-prone for the wide range of unexpected
inputs that might be required. So, as per 
https://stackoverflow.com/questions/28881758/how-can-i-use-spaces-in-systemd-command-line-arguments, exporting  arguments
as environment variables and using those environment variables in the argument list seems to be the generally accepted
way of escaping arguments to systemd unit commands.

According to [this pull request](https://github.com/systemd/systemd/pull/13698), `\n` in environment variable values will
be expanded to newlines since systemd v239. Prior to this version, newlines are not supported in environment variables.

## Logging

Both the logging driver, as well as any associated options can be configured on all instances in the pool Sensible
defaults for the `local` and `json-file` log drivers are provided. The defaults for these drivers are provided below:

### local

```terraform
local = {
  max-size = "50m"
  max-file = "10"
  compress = "true"
}
```

### json-file

```terraform
json-file = {
  max-size = "50m"
  max-file = "10"
  compress = "true"
}
```

## Health checks

Instances in the worker pool can be checked regularly to ensure they're still healthy and eligible to be in the pool.

Worker pool health checks ensure that all the requested workers are running (and the CloudSQL container if
`var.cloudsql.connections` is not empty). If all workers are running, a port is opened on the instance for access by
Google Cloud's health checks. If at least one worker is not running, this port will be closed - causing the health
checks to start failing, and the unhealthy instance to be recreated in the worker pool.

## Exposing workers

It is also possible to expose ports on workers. However, this is not possible when `var.workers.replicas` > 1. Simply
populate the `var.workers.expose` attribute to begin exposing ports.

Below is an example of the minimum configuration required to expose nginx in a pool on port 80:

```terraform
module my_nginx {
  source = "garbetjie/worker-pool/google"
  
  // ...
  workers = {
    image = "nginx:latest"
    replicas = 1
    expose = [{ port = 80 }]
  }
  // ...
}
```

# Outputs

All inputs are exported as outputs. There are additional outputs as defined below:

| Name                             | Description                                                       | Type   |
|----------------------------------|-------------------------------------------------------------------|--------|
| instance_group_manager_self_link | Self link of the instance group manager.                          | string |
| instance_group_self_link         | Self link of the instance group.                                  | string |
| instance_template_self_link      | Self link to the created instance template.                       | string |
| regional                         | Flag indicating if a regional instance group manager was created. | bool   |
| tag                              | Unique tag generated for instance targeting in firewall rules.    | string |

# Changelog

* **2.0.0**
  * Completely refactor input configuration.
  * Default most attributes for timers to those supplied for workers.
  
* **1.5.0**
  * Add ability to specify user workers & timers run as.

* **1.4.0**
  * Add mounting of volumes into workers.

* See [CHANGELOG.md](CHANGELOG.md) for a full history.

# Roadmap

The points listed below are features that have been considered for possible inclusion in the future. There are no
guarantees as to whether these features will ever make it into the final module:

* **Sidecar containers.**
  
  The ability to run arbitrary containers as sidecars on each instance.
  Not sure whether these should be limited to using the top-level image/env (like timers), otherwise configuration
  becomes much trickier.
  
* **Autoscaling.**
  
  Ideally, it would be great to be able to customise the instance group to scale automatically - either by custom
  Stackdriver metric, or by CPU usage. First prize would be to enable autoscaling by custom metric.
  
* **Waiting for CloudSQL: TCP ports**
  
  Currently, when waiting for CloudSQL to start, only socket connections are checked. If CloudSQL is actually listening
  on a TCP connection, the script will never know.

* **Customising the health check port when ports are exposed.**

  When ports are exposed, they're never taken into account when it comes to health checks. Perhaps the default health
  check port exposing should be used if no ports are exposed.
  
  If there are any ports exposed, then rather default to checking those ports?