Changelog
=========

* **2.0.1**
  * Replaced erroneous `echo` with `exec` in timer script.

* **2.0.0**
    * Completely refactor input configuration.
    * Default most attributes for timers to those supplied for workers.

* **1.5.0**
    * Add ability to specify user workers & timers run as.

* **1.4.0**
    * Add mounting of volumes into workers.

* **1.3.0**
    * Add ability to customise metadata.

* **1.2.0**
    * Define a proper structure for `var.expose_ports`.

* **1.1.0**
    * Add changelog to documentation.
    * Add ability to expose ports.
    * Add `tag` output.

* **1.0.1**
    * Ensure service arguments with spaces work correctly.

* **1.0.0**
    * Documentation update.
    * Add inputs as outputs.
    * Add ability to configure timezone & network tags on instances.

* **0.8.1**
    * Remove `google-beta` provider-specific functionality.

* **0.8.0**
    * Add health checks.
    * Make `wait_for_instances` configurable.

* **0.7.1**
    * Fix incorrect functions used for generating command argument lists.

* **.0.7.0**
    * Change `var.args` and `var.timers.*.args` to `var.command` and `var.timers.*.command`.
    * Fix naming of argument environment variables.

* **0.6.0**
    * Make CloudSQL wait duration configurable.

* **0.5.0**
    * Add `var.runcmd` to run arbitrary commands on startup.
    * Add waiting for CloudSQL to start up.