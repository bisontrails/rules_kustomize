.. role:: command(emphasis)
.. role:: field(code)
.. role:: file(emphasis)
.. role:: cmdflag(code)
.. role:: krmkind(emphasis)
.. role:: macro(code)
.. role:: pfield(code)
.. role:: ruleattr(kbd)
.. role:: term(emphasis)
.. role:: tool(emphasis)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**

=================================
:tool:`kustomize` rules for Bazel
=================================

.. External links
.. _kustomization term: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization
.. See https://stackoverflow.com/a/4836544/31818 for this abomination:
.. |the kustomize tool| replace:: the :tool:`kustomize` tool
.. _the kustomize tool:
.. _kustomize: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomize
.. _resources:
.. _resource: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#resource
.. _root: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization-root

Integrate |the kustomize tool|_ into your Bazel projects to build Kubernetes-style manifests.

.. contents:: :depth: 2

-----

Overview
========

These Bazel rules allow you to define `kustomizations <kustomization term_>`__ within your project workspace and capture the output of *building* those kustomizations with |the kustomize tool|_. Using :tool:`kustomize` within a Bazel project orchestrates both the preparation of the input files—for when static files won't do—and consumption of the resulting YAML document stream, situating :tool:`kustomize` as a transformer in the middle of that data flow.

:tool:`kustomize` operates on the Kubernetes Resource Model (KRM), and most often comes into play just ahead of Kubernetes API clients like :tool:`kubectl`, sending the YAML document stream to the Kubernetes API to apply the resources_ to the cluster. These rules do no include any such interaction with the Kubernetes API. Instead, they focus solely on emitting the resources defined by the :term:`kustomization`.

Simple Example
--------------

Here we'll walk through a simple example to give a feel for how to use these Bazel rules.

Assume you have a :term:`kustomization` that defines a single Kubernetes :krmkind:`ConfigMap`, taking its data entries from both a file containing "environment variable"-style line-by-line definitions and some inline definitions in the :file:`kustomization.yaml` file. First, the :file:`kustomization.yaml` file:

.. code:: yaml

    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    configMapGenerator:
    - name: translations
      envs:
      - config-bindings
      literals:
      - HELLO=hola
      - GOODBYE=adios

Note that the "envs" field references a sibling file named :file:`config-bindings`, with content as follows:

.. code::

    THANK_YOU=gracias

If we run the :command:`kustomize build` command against the directory containing these two files, it emits the following YAML document:

.. code:: yaml

    apiVersion: v1
    data:
      GOODBYE: adios
      HELLO: hola
      THANK_YOU: gracias
    kind: ConfigMap
    metadata:
      name: translations-74424tmdd8

Now, let's teach Bazel to produce the same document.

By convention, we'll add a couple of Bazel targets to the :file:`BUILD.bazel` file in the same directory. First, we define the `kustomization <kustomization term_>`__ itself, indicating where the :term:`kustomization` file sits and which other files it depends on. For this, we use the kustomization_ rule.

.. code:: bazel

   load(
        "@co_bisontrails_rules_kustomize//kustomize:kustomize.bzl",
        "kustomization",
    )

    kustomization(
        name = "base",
        srcs = [
            "config-bindings",
        ],
    )

By default, the kustomization_ rule assumes the :file:`kustomization` file is named :file:`kustomization.yaml`, but you can also point it at other file names, such as the :file:`kustomization.yml` or :file:`kustomization` alternatives that the :tool:`kustomize` tool accepts.

This "base" target we've defined doesn't produce any artifacts. It prepares the recipe for building artifacts, in the same way that a :term:`kustomization`'s files are inert input for the :tool:`kustomize` tool. When we'd like to build the :term:`kustomization` using particular options—as we would by invoking :command:`kustomize build`—we define another target in a :file:`BUILD.bazel` file. Here we'll add to the same Bazel package, this time using the kustomized_resources_ rule.

.. code:: bazel
    load(
        "@co_bisontrails_rules_kustomize//kustomize:kustomize.bzl",
        "kustomized_resources",
    )

    kustomized_resources(
        name = "simple",
        kustomization = ":base",
    )

When we tell Bazel to build this new "simple" target, it will invoke :command:`kustomize build` and write the output to a file named :file:`simple.yaml`. That's the default mapping from target name to output file name, but you can change it with the kustomized_resources_ rule's :ruleattr:`result` attribute. Other Bazel targets can then demand this file as input, forcing Bazel to rebuild the file whenever—and only when—any of the input files change.

Integrating Into Your Project
=============================

In order to use these rules in your Bazel project, you must instruct Bazel to download the source and run the functions that make the rules available. Add the following to your project's :file:`WORKSPACE` (or :file:`WORKSPACE.bazel`) file.

.. code:: bazel

    load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

    http_archive(
        name = "co_bisontrails_rules_kustomize",
        sha256 = "TODO(seh)",
        urls = [
            # TODO(seh): Establish a URL to a release.
            "https://github.com/bisontrails/rules_bazel/releases/download/v0.1.0/rules_go-v0.1.0.tar.gz",
        ],
    )

    load(
        "@co_bisontrails_rules_kustomize//kustomize:repositories.bzl",
        "helm_register_tool",
        "kustomize_register_tool",
    )

    helm_register_tool()
    kustomize_register_tool()

The latter two macros—:macro:`helm_register_tool` and :macro:`kustomize_register_tool`—each register a particular version of the :tool:`helm` and :tool:`kustomize` tools, respectively. By default, these macros register `the latest version known to the rules <Tool Versions_>`_. You can specify a preferred version for each by passing the known version slug (e.g. "v4.1.2") as an argument to the function.

With those calls in place, you're now ready to use the rules in your Bazel packages.

Tool Versions
=============

At present, these rules can load the following versions of these tools:

* :tool:`kustomize`

  * `v4.1.2 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv4.1.2>`__ (default)

* :tool:`helm`

  * `v3.5.4 <https://github.com/helm/helm/releases/tag/v3.5.4>`__ (default)

Rules
=====

kustomization
-------------

This defines a `kustomization <kustomization term_>`__ from a set of source files and other `kustomizations <kustomization_>`_, intended for referencing from one or more dependent kustomized_resources_ targets.

Providers
^^^^^^^^^

* KustomizationInfo_

Attributes
^^^^^^^^^^
+-----------------------------------------+-----------------------------+---------------------------------------+
| **Name**                                | **Type**                    | **Default value**                     |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`name`                        | :type:`string`              | |mandatory|                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| A unique name for the :term:`kustomization`. As there is usually only one such target defined  per Bazel      |
| package (assuming that the target is in the same package as the :term:`kustomization` file), a simple name    |
| like "base" is fitting.                                                                                       |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`deps`                        | :type:`label_list`          | :value:`[]`                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| The set of `kustomizations <kustomization_>`_ referenced as resources_ by this :term:`kustomization`.         |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`file`                        | :type:`label`               | :value:`kustomization.yaml`           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :file:`kustomization.yaml`, :file:`kustomization.yml`, or :file:`kustomization` file for this                 |
| :term:`kustomization`.                                                                                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_exec_functions`     | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of exec functions (raw executables) (per the                  |
| :cmdflag:`--enable-exec` :tool:`kustomize` flag).                                                             |
|                                                                                                               |
| Even if this :term:`kustomization`'s top-level resources don't require such use but any of its base           |
| :term:`kustomizations` do, this value is effectively :value:`True`.                                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_helm`               | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of the Helm chart inflator generator (per the                 |
| :cmdflag:`--enable-helm` :tool:`kustomize` flag).                                                             |
|                                                                                                               |
| Even if this :term:`kustomization`'s top-level resources don't require such use but any of its base           |
| :term:`kustomizations` do, this value is effectively :value:`True`.                                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_plugins`            | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of :tool:`kustomize` plugins (per the                         |
| :cmdflag:`--enable-alpha-plugins` :tool:`kustomize` flag).                                                    |
|                                                                                                               |
| Even if this :term:`kustomization`'s top-level resources don't require such use but any of its base           |
| :term:`kustomizations` do, this value is effectively :value:`True`.                                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_starlark_functions` | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of Starlark functions (per the :cmdflag:`--enable-star`       |
| :tool:`kustomize` flag).                                                                                      |
|                                                                                                               |
| Even if this :term:`kustomization`'s top-level resources don't require such use but any of its base           |
| :term:`kustomizations` do, this value is effectively :value:`True`.                                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`srcs`                        | :type:`label_list`          | :value:`[]`                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Files referenced as resources_ for this :term:`kustomization`.                                                |
+-----------------------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: bazel

    kustomization(
        name = "overlay",
        deps = [
            # This target "base:base" is another kustomization.
            "//apps/base"
        ],
        # We can omit the "file" attribute because our kustomization
        # file is named "kustomization.yaml," matching the default.
        srcs = [
            # This target "charts:charts" is a filegroup.
            "//apps/base/charts",
            "extras.yaml",
        ],
        requires_helm = True,
    )

kustomized_resources
--------------------

This defines an invocation of the :command:`kustomize build` command against a :term:`kustomization` `target <https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#target>`_, creating a resulting set of :term:`resources` (collectively, a `variant <https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#variant>`_).

See the Difficulties_ section below for considerations both with :term:`kustomizations` that involve use of the :field:`helmCharts` :krmkind:`Kustomization` (or :krmkind:`Component`) field and when executing Bazel actions on some computers.

Attributes
^^^^^^^^^^

+---------------------------------------+-----------------------------+---------------------------------------+
| **Name**                              | **Type**                    | **Default value**                     |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`name`                      | :type:`string`              | |mandatory|                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| A unique name for the :term:`variant`.                                                                      |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`enable_managed_by_label`   | :type:`bool`                | :value:`False`                        |
+---------------------------------------+-----------------------------+---------------------------------------+
| Enable adding the "app.kubernetes.io/managed-by" label to objects (per the                                  |
| :cmdflag:`--enable-managedby-label` :tool:`kustomize` flag).                                                |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`env_bindings`              | :type:`string_dict`         | :value:`{}`                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| Names and values of environment variables to be used by functions (per the :cmdflag:`--env`                 |
| :tool:`kustomize` flag).                                                                                    |
|                                                                                                             |
| These bindings specify a value for each environment variable. To forward an exported environment variable's |
| through instead, use the :ruleattr:`env_exports` attribute.                                                 |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`env_exports`               | :type:`string_list`         | :value:`[]`                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| Names of exported environment variables to be used by functions (per the :cmdflag:`--env` :tool:`kustomize` |
| flag).                                                                                                      |
|                                                                                                             |
| These bindings forward each exported environment variable's value. To specify a value for each environment  |
| variable instead, use the :ruleattr:`env_bindings` attribute.                                               |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`kustomization`             | :type:`label`               | |mandatory|                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| The :term:`kustomization` to build.                                                                         |
|                                                                                                             |
| This may refer to a target using the kustomization_ rule or another rule that yields a KustomizationInfo_   |
| provider.                                                                                                   |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`load_restrictor`           | :type:`string`              | :value:`RootOnly`                     |
+---------------------------------------+-----------------------------+---------------------------------------+
| Control whether :term:`kustomizations` may load files from outsider their root directory (per the           |
| :cmdflag:`--load-restrictor` :tool:kustomize flag). May be one of :value:`None` or :value:`RootOnly`.       |
|                                                                                                             |
| See the Difficulties_ section for cases where you may need to set this value to :value:`None` within        |
| Bazel when you could normally get by with the :tool:`kustomize` tool's default behavior of preventing       |
| :term:`kustomizations` from loading files from outside their root_.                                         |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`reorder_resources`         | :type:`bool`                | :value:`True`                         |
+---------------------------------------+-----------------------------+---------------------------------------+
| Whether to reorder the :term:`kustomization`'s resources_ just before writing them as output (per the       |
| :cmdflag:`--reorder` :tool:`kustomize` flag).                                                               |
|                                                                                                             |
| The default value uses the :tool:kustomize tool's "legacy" reodering. See the                               |
| kubernetes-sigs/kustomize#3794 and kubernetes-sigs/kustomize#3829 issues for discussion about how this      |
| sorting behavior might change.                                                                              |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`result`                    | :type:`output`              | :value:`<name>.yaml`                  |
+---------------------------------------+-----------------------------+---------------------------------------+
| The built result, as a YAML stream of KRM resources in separate documents (per the :cmdflag:`--output`      |
| :tool:`kustomize` flag).                                                                                    |
+---------------------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: bazel

    kustomized_resources(
        name = "production",
        env_bindings = {
            "CLUSTER_NAME": "prod1234",
            "ENVIRONMENT": "production",
        },
        kustomization = ":overlay",
    )

Providers
=========

KustomizationInfo
-----------------

:type:`KustomizationInfo` summarizes a :term:`kustomization` root_, as provided by the kustomization_ rule.

Fields
^^^^^^

+---------------------------------------+----------------------------------------------------------+
| **Name**                              | **Type**                                                 |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_exec_functions`     | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of exec functions (raw executables) (per the     |
| :cmdflag:`--enable-exec` :tool:`kustomize` flag).                                                |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_helm`               | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of the Helm chart inflator generator (per the    |
| :cmdflag:`--enable-helm` :tool:`kustomize` flag).                                                |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_plugins`            | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of :tool:`kustomize` plugins (per the            |
| :cmdflag:`--enable-alpha-plugins` :tool:`kustomize` flag).                                       |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_starlark_functions` | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of Starlark functions (per the                   |
| :cmdflag:`--enable-star` :tool:`kustomize` flag).                                                |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`root`                        | :type:`string`                                           |
+---------------------------------------+----------------------------------------------------------+
| The directory immediately containing the :term:`kustomization` file defining this                |
| :term:`kustomization`.                                                                           |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`transitive_resources`        | :type:`depset of File`                                   |
+---------------------------------------+----------------------------------------------------------+
| The set of files (including other :term:`kustomizations`) referenced by this                     |
| :term:`kustomization`.                                                                           |
+---------------------------------------+----------------------------------------------------------+

Difficulties
============

Bazel's Sandbox and Load Restrictors
------------------------------------

Downloading Helm Charts
-----------------------
