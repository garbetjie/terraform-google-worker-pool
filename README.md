Terraform Module: Google Workers
================================

A Terraform module for the [Google Cloud Platform](https://cloud.google.com) that makes it easy to create a group of
background workers running in a Docker container.

# Table Of Contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
  * Timers
  * Argument escaping
  * [Default log driver options](#default-log-driver-options)
* [Inputs](#inputs)
* Outputs
* [Roadmap](#roadmap)

# Introduction

Many systems require workers that process jobs in the background. Typically, these jobs are not time sensitive, and will
take longer to run that what is acceptable for most user interfaces.

This Terraform module makes it very simple & easy to create a
[Managed Instance Group](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) that is able to
run multiple workers per server. If any CloudSQL connections are required, a sidecar container is automatically created
that will manage the connections to the database, and provide them as UNIX sockets available through a shared volume.

In order to save costs, the instances created by this module are
[preemptible](https://cloud.google.com/compute/docs/instances/preemptible), as background workers typically aren't
required to be available 24/7.

# Requirements

* Terraform >= 0.13

# Usage

The usage shown below is with the least amount of configuration possible. All the possible inputs are documented in the
[Inputs](#inputs) section.

```terraform
module worker {
  source = "garbetjie/worker/google"
  
  name = "worker"
  workers_per_instance = 1
  location = "europe-west4"
  image = "garbetjie/php:7.4-nginx"
}
```

## Timers

## Argument escaping

## Default log driver options

Sensible defaults for the `local` and `json-file` log drivers are provided. The defaults for these drivers are provided
below:

### local

```terraform
local = {
  max-size = "50m"
  max-file = "5"
  compress = "true"
}
```

### json-file

```terraform
json-file = {
  max-size = "50m"
  max-file = "5"
  compress = "true"
}
```

# Inputs

| Name                  | Description                                                                                                                                                      | Type                                                                    | Default       | Required |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------|---------------|----------|
| name                  | Name of the worker group.                                                                                                                                        | string                                                                  |               | Yes      |
| image                 | Docker image to use.                                                                                                                                             | string                                                                  |               | Yes      |
| location              | Location in which to create the group (if a region is supplied, a regional instance group manager will be created).                                              | string                                                                  |               | Yes      |
| workers_per_instance  | The number of workers to run on each instance.                                                                                                                   | number                                                                  |               | Yes      |
| args                  | Arguments to pass to each worker.                                                                                                                                | list(string)                                                            | `[]`          | No       |
| cloudsql_connections  | Instance names of CloudSQL instances to maintain connections to.                                                                                                 | set(string)                                                             | `[]`          | No       |
| cloudsql_path         | If `cloudsql_connections` is populated, this is the directory path in each worker to which the UNIX socket connection is mounted.                                | string                                                                  | `/cloudsql`   | No       |
| disk_size             | Size (in GB) of the disk to attach to instances.                                                                                                                 | number                                                                  | `25`          | No       |
| disk_type             | Type of disk to attach to instances. Must be one of \[`pd-ssd`, `local-ssd`, `pd-balanced`, `pd-standard`\].                                                     | string                                                                  | `pd-balanced` | No       |
| env                   | Environment variables to inject into each worker & timer.                                                                                                        | map(string)                                                             | `{}`          | No       |
| instance_count        | Number of instances to create in the group.                                                                                                                      | number                                                                  | `1`           | No       |
| labels                | Map of [labels](https://cloud.google.com/run/docs/configuring/labels) to apply to instances.                                                                     | map(string)                                                             | `{}`          | No       |
| log_driver            | Default Docker [log driver](https://docs.docker.com/config/containers/logging/configure) to use.                                                                 | string                                                                  | `local`       | No       |
| log_opts              | Options to supply to configured log driver. Sensible defaults are used and [are documented](#default-log-driver-options) above.                                  | map(string)                                                             | `null`        | No       |
| machine_type          | Type of machine to create instances as.                                                                                                                          | string                                                                  | `f1-micro`    | No       |
| network               | Name of the network to create instances in.                                                                                                                      | string                                                                  | `default`     | No       |
| preemptible           | Flag indicating whether or not to create [preemptible](https://cloud.google.com/compute/docs/instances/preemptible) instances.                                   | bool                                                                    | `true`        | No       |
| service_account_email | Service account to run each instance with.                                                                                                                       | string                                                                  | `null`        | No       |
| timers                | Scheduled [timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html) to create.                                                               | list(object({ name = string, schedule = string, args = list(string) })) | `[]`          | No       |
| timers.name           | Name of the timer to create. This is used to name the container, service unit and timer unit for this timer.                                                     | string                                                                  |               | Yes      |
| timers.schedule       | The schedule on which this timer should run. The [`OnCalendar`](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#OnCalendar=) format is used. | string                                                                  |               | Yes      |
| timers.args           | Arguments to pass to the timer.                                                                                                                                  | list(string)                                                            |               | Yes      |
| worker_name           | Name of the systemd unit used to run each worker. This is configurable to ensure it doesn't clash with names of timers.                                          | string                                                                  | `worker`      | No       |

# Outputs

# Roadmap

The points listed below are features that have been considered for possible inclusion in the future. There are no
guarantees as to whether these features will ever make it into the final module:

* **Sidecar containers.**
  The ability to run arbitrary contains as sidecars on the instance.
  Not sure whether these should be limited to using the top-level image/env (like timers). 
  
* **Autoscaling.**
  Ideally, it would be great to be able to customise the instance group to scale automatically - either by custom
  Stackdriver metric, or by CPU usage. First prize would be to enable autoscaling by custom metric.

* **Health checks for autohealing.**
  It would be great to be able to implement [autohealing](https://cloud.google.com/compute/docs/instance-groups#autohealing)
  on created instances.
  
  Initial thoughts are around running some kind of TCP server on a configurable port that will stop if any of the workers
  die permanently.
  
  What if 1/5 workers are still running? Should it fail? Should we stop the health check as soon as the first worker
  fails permanently?

