Terraform Module: Google Workers
================================

A Terraform module for the [Google Cloud Platform](https://cloud.google.com) that makes it easy to create a group of
background workers running in a Docker container.

# Table Of Contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
  * [CloudSQL](#cloudsql)
  * [Timers](#timers)
  * [Argument escaping](#argument-escaping)
  * [Default log driver options](#default-log-driver-options)
* [Inputs](#inputs)
* [Outputs](#outputs)
* [Roadmap](#roadmap)

# Introduction

Many systems require workers that process jobs in the background. Typically, these jobs are not time sensitive, and will
take longer to run that what is acceptable for most user interfaces.

This Terraform module makes it very simple & easy to create a
[Managed Instance Group](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) that is able to
run multiple workers per server. If any CloudSQL connections are required, a sidecar container is automatically created
that will manage the connections to the database, and provide them as UNIX sockets available through a shared volume.

In order to save costs, the instances created by this module are
[preemptible](https://cloud.google.com/compute/docs/instances/preemptible), as background workers are typically able to
handle temporary interruptions in execution.

# Requirements

* Terraform >= 0.14

# Usage

The usage shown below is with the least amount of configuration possible. All the possible inputs are documented in the
[Inputs](#inputs) section.

```terraform
module worker {
  source = "garbetjie/worker-pool/google"
  
  name = "my-pool"
  workers_per_instance = 1
  location = "europe-west4"
  image = "garbetjie/php:7.4-cli"
  args = ["php", "-S", "localhost:8000"]
}
```

## CloudSQL

When specifying at least one CloudSQL connection in the `var.cloudsql_connections` input, an automatic dependency on
CloudSQL is created for you - making it simple to securely connect to your CloudSQL instances.

A `cloudsql.service` systemd unit is generated, and is added as a hard requirement to workers and timers - if the CloudSQL
service fails to start, no workers or timers will run. Additionally, a volume is automatically mounted into all workers
and timers at the directory specified by `var.cloudsql_path` (defaults to `/cloudsql`) containing the UNIX sockets
that can be used to connect to the specified CloudSQL instances.

The given connection names are passed straight through to the CloudSQL Proxy. This makes it possible to [specify TCP ports
for connections to be available on](https://cloud.google.com/sql/docs/mysql/connect-admin-proxy#start-proxy). Keep in mind
that because everything is running in Docker, using the `tcp:PORT_NUMBER` format will more than likely not work, as
`127.0.0.1` will refer to the Docker container from which the CloudSQL Proxy is being run.

> This requires the `roles/cloudsql.client` IAM role to be populated on the service account the instances run as.

## Timers

Using timers in systemd is the way to schedule tasks that need to be run on a regular basis - systemd's replacement for
cron jobs. Timers in this module inherit the `var.image` and `var.env` values that are specified for workers, and also
inherit the CloudSQL dependency if `var.cloudsql_connections` is populated.

> When specifying the schedule on which timers should run, it is the
[`OnCalendar`](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#OnCalendar=) property that is populated.
[This page](https://www.freedesktop.org/software/systemd/man/systemd.time.html#Calendar%20Events) contains more information
on the allowed formats of this property.

## Argument escaping

Arguments passed in `var.args` and `var.timers.*.args` are escaped, and can safely contain spaces, strings and any number
of values. How this is achieved is outlined below:

Terraform provides no way to escape strings for use in shell scripts, and using regular expressions to accomplish this
task is going to make it too complex and error-prone for the wide range of unexpected inputs that might be required.

So, as per https://stackoverflow.com/questions/28881758/how-can-i-use-spaces-in-systemd-command-line-arguments, exporting 
arguments as environment variables and using those environment variables in the argument list seems to be the generally
accepted way of escaping arguments to systemd unit commands.

According to [this pull request](https://github.com/systemd/systemd/pull/13698), `\n` in environment variable values will
be expanded to newlines since systemd v239. Prior to this version, newlines are not supported in environment variables.

## Default log driver options

Sensible defaults for the `local` and `json-file` log drivers are provided. The defaults for these drivers are provided
below:

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

# Inputs

| Name                  | Description                                                                                                                                                      | Type                                                                              | Default         | Required |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|-----------------|----------|
| name                  | Name of the pool.                                                                                                                                                | string                                                                            |                 | Yes      |
| image                 | Docker image on which the workers are based.                                                                                                                     | string                                                                            |                 | Yes      |
| location              | Zone or region in which to create the pool.                                                                                                                      | string                                                                            |                 | Yes      |
| workers_per_instance  | Number of workers to start up per instance.                                                                                                                      | number                                                                            |                 | Yes      |
| args                  | Arguments to pass to each worker. See the notes about [argument escaping](#argument-escaping) for information on formatting.                                     | list(string)                                                                      | `[]`            | No       |
| cloudsql_connections  | List of CloudSQL connections to establish before starting workers.                                                                                               | set(string)                                                                       | `[]`            | No       |
| cloudsql_path         | The path at which CloudSQL connection sockets will be available in workers and timers.                                                                           | string                                                                            | `"/cloudsql"`   | No       |
| disk_size             | Disk size (in GB) to create instances with.                                                                                                                      | number                                                                            | `25`            | No       |
| disk_type             | Disk type to create instances with. Must be one of \[`pd-ssd`, `local-ssd`, `pd-balanced`, `pd-standard`\].                                                      | string                                                                            | `"pd-balanced"` | No       |
| env                   | Environment variables to inject into workers and timers.                                                                                                         | map(string)                                                                       | `{}`            | No       |
| instance_count        | Number of instances to create in the pool.                                                                                                                       | number                                                                            | `1`             | No       |
| labels                | [Labels](https://cloud.google.com/run/docs/configuring/labels) to apply to all instances in the pool.                                                            | map(string)                                                                       | `{}`            | No       |
| log_driver            | Default [log driver](https://docs.docker.com/config/containers/logging/configure) to be used in the Docker daemon.                                               | string                                                                            | `"local"`       | No       |
| log_opts              | Options for configured log driver. Sensible defaults are used and [are documented](#default-log-driver-options) above.                                           | map(string)                                                                       | `null`          | No       |
| machine_type          | Machine type to create instances in the pool with.                                                                                                               | string                                                                            | `"f1-micro"`    | No       |
| network               | Network name or link in which to create the pool.                                                                                                                | string                                                                            | `"default"`     | No       |
| preemptible           | Whether or not to create [preemptible](https://cloud.google.com/compute/docs/instances/preemptible) instances.                                                   | bool                                                                              | `true`          | No       |
| service_account_email | Service account to assign to the pool.                                                                                                                           | string                                                                            | `null`          | No       |
| systemd_name          | Name of the systemd service for workers. This is configurable to ensure it doesn't clash with names of timers.                                                   | string                                                                            | `"worker"`      | No       |
| timers                | Scheduled [timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html) to create.                                                               | list(object({ name = string, schedule = string, args = optional(list(string)) })) | `[]`            | No       |
| timers.*.name         | Name of the timer to create. This is used to name the container, service unit and timer unit for this timer.                                                     | string                                                                            |                 | Yes      |
| timers.*.schedule     | The schedule on which this timer should run. The [`OnCalendar`](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#OnCalendar=) format is used. | string                                                                            |                 | Yes      |
| timers.*.args         | Arguments to pass to the timer. See the notes about [argument escaping](#argument-escaping) for information on formatting.                                       | list(string)                                                                      | `[]`            | No       |

# Outputs

All inputs are exported as outputs. There are additional outputs as defined below:

| Name                        | Description                                                                           | Type        |
|-----------------------------|---------------------------------------------------------------------------------------|-------------|
| regional_manager_self_link  | Self link of the instance group manager when a region is specified in `var.location`. | string      |
| zonal_manager_self_link     | Self link of the instance group manager when a zone is specified in `var.location`.   | string      |
| instance_template_self_link | Self link to the created instance template.                                           | string      |
| regional                    | Flag indicating if a regional instance group manager was created.                     | bool        |

# Roadmap

The points listed below are features that have been considered for possible inclusion in the future. There are no
guarantees as to whether these features will ever make it into the final module:

* **Customizing of the restart policy.**
  
  The `RestartPolicy` for workers should be configurable, as well as any timings/duration that aide in determining whether
  a worker should be restarted or not.

* **Sidecar containers.**
  
  The ability to run arbitrary containers as sidecars on each instance.
  Not sure whether these should be limited to using the top-level image/env (like timers), otherwise configuration
  becomes much trickier.
  
* **Autoscaling.**
  
  Ideally, it would be great to be able to customise the instance group to scale automatically - either by custom
  Stackdriver metric, or by CPU usage. First prize would be to enable autoscaling by custom metric.
  
* **Exposing ports**

  Ideally, it should be possible to expose ports from the worker containers. This can make it possible for workers to be
  communicated with in some form.

* **Health checks for autohealing.**
  
  It would be great to be able to implement [autohealing](https://cloud.google.com/compute/docs/instance-groups#autohealing)
  on created instances.
  
  Initial thoughts are around running some kind of TCP server on a configurable port that will stop if any of the workers
  die permanently.
  
  What if 1/5 workers are still running? Should it fail? Should we stop the health check as soon as the first worker
  fails permanently?

