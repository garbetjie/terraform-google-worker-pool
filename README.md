Terraform Module: Google Workers
================================

A Terraform module for the [Google Cloud Platform](https://cloud.google.com) that makes it easy to create a group of
background workers running in a Docker container.

# Table Of Contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Inputs](#inputs)
* [Outputs](#outputs)

# Introduction

Many systems require workers that process jobs in the background. Typically, these jobs are not time sensitive, and will
take longer to run that what is acceptable for most user interfaces.

This Terraform module makes it very simple & easy to create a
[Managed Instance Group](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) that is able to
run multiple workers per server. In order to save costs, the instances created by this module are
[preemptible](https://cloud.google.com/compute/docs/instances/preemptible), as background workers typically aren't
required to be available 24/7.

# Requirements

* Terraform >= 0.13

# Usage

```terraform
module worker {
  source = "garbetjie/worker/google"
  
  name = "worker"
  workers_per_instance = 1
  location = "europe-west4"
  image = "garbetjie/php:7.4-nginx"
}
```
