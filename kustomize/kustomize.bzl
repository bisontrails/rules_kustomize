KustomizationInfo = provider(
    doc = "Kustomization root summary",
    fields = {
        "requires_exec_functions": "Whether this kustomization requires use of exec functions (raw executables).",
        "requires_helm": "Whether this kustomization requires use of the Helm chart inflator generator.",
        "requires_plugins": "Whether this kustomization requires use of kustomize plugins.",
        "requires_starlark_functions": "Whether this kustomization requires use of Starlark functions.",
        "root": "The directory immediately containing the kustomization file defining this kustomization.",
        "transitive_resources": "The set of files (including other kustomizations) referenced by this kustomization.",
    },
)

_kustomization_attrs = {
    "deps": attr.label_list(
        doc = "The set of kustomizations referenced as resources by this kustomization.",
        providers = [KustomizationInfo],
    ),
    "file": attr.label(
        doc = "kustomization.yaml, kustomization.yml, or kustomization file for this kustomization.",
        allow_single_file = True,
    ),
    "requires_exec_functions": attr.bool(
        doc = """Whether this kustomization requires use of exec functions (raw executables).

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "requires_helm": attr.bool(
        doc = """Whether this kustomization requires use of the Helm chart inflator generator.

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "requires_plugins": attr.bool(
        doc = """Whether this kustomization requires use of kustomize plugins.

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "requires_starlark_functions": attr.bool(
        doc = """Whether this kustomization requires use of Starlark functions.

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "srcs": attr.label_list(
        doc = "Files referenced as resources for this kustomization.",
        allow_files = True,
    ),
}

def _kustomization_impl(ctx):
    return [
        KustomizationInfo(
            requires_exec_functions =
                ctx.attr.requires_exec_functions or
                any([dep[KustomizationInfo].requires_exec_functions for dep in ctx.attr.deps]),
            requires_helm =
                ctx.attr.requires_helm or
                any([dep[KustomizationInfo].requires_helm for dep in ctx.attr.deps]),
            requires_plugins =
                ctx.attr.requires_plugins or
                any([dep[KustomizationInfo].requires_plugins for dep in ctx.attr.deps]),
            requires_starlark_functions =
                ctx.attr.requires_starlark_functions or
                any([dep[KustomizationInfo].requires_starlark_functions for dep in ctx.attr.deps]),
            root = ctx.file.file.dirname,
            transitive_resources = depset(
                direct = [ctx.file.file] + ctx.files.srcs,
                transitive = [dep[KustomizationInfo].transitive_resources for dep in ctx.attr.deps],
            ),
        ),
    ]

_kustomization = rule(
    attrs = _kustomization_attrs,
    implementation = _kustomization_impl,
)

def kustomization(name, **kwargs):
    file = kwargs.pop("file", "kustomization.yaml")

    _kustomization(
        name = name,
        file = file,
        **kwargs
    )

_kustomized_resources_attrs = {
    "enable_managed_by_label": attr.bool(
        doc = "Enable adding the 'app.kubernetes.io/managed-by' label to objects.",
    ),
    "env_bindings": attr.string_dict(
        doc = "Names and values of environment variables to be used by functions.",
    ),
    "env_exports": attr.string_list(
        doc = "Names of exported environment variables to be used by functions.",
    ),
    "_helm": attr.label(
        doc = "Helm tool to use for inflating Helm charts.",
        default = "//kustomize:helm",
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "kustomization": attr.label(
        doc = "kustomization to build.",
        mandatory = True,
        providers = [KustomizationInfo],
    ),
    "_kustomize": attr.label(
        doc = "kustomize tool to use for building kustomizations.",
        default = ":kustomize",
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "load_restrictor": attr.string(
        doc = "Control whether kustomizations may load files from outsider their root directory.",
        values = [
            "None",
            "RootOnly",
        ],
        default = "RootOnly",
    ),
    "reorder_resources": attr.bool(
        doc = "Whether to reorder resources just before writing them as output.",
        default = True,
    ),
    "result": attr.output(
        doc = "The built result, as a YAML stream of KRM resources in separate documents.",
        mandatory = True,
    ),
}

def _kustomized_resources_impl(ctx):
    kustomization = ctx.attr.kustomization[KustomizationInfo]
    args = ctx.actions.args()
    args.add("build")
    args.add(kustomization.root)
    if kustomization.requires_helm:
        args.add("--enable-helm")
        args.add("--helm-command", ctx.executable._helm.path)
    if kustomization.requires_exec_functions:
        args.add("--enable-exec")
    if kustomization.requires_plugins:
        args.add("--enable-alpha-plugins")
    if kustomization.requires_starlark_functions:
        args.add("--enable-star")
    if ctx.attr.enable_managed_by_label:
        args.add("--enable-managedby-label")

    # Place exported environment varibles first, allowing shadowing by
    # explicit bindings
    for name in ctx.attr.env_exports:
        if len(name) == 0:
            fail(msg = "exported environment variable name must not be empty")
        args.add("--env", name)
    for name, v in ctx.attr.env_bindings.items():
        if len(name) == 0:
            fail(msg = "bound environment variable name must not be empty")
        args.add(
            "--env",
            "{}={}".format(name, v),
        )
    if ctx.attr.load_restrictor != "RootOnly":
        args.add("--load-restrictor", "LoadRestrictionsNone")
    args.add("--reorder", "legacy" if ctx.attr.reorder_resources else "none")
    args.add("--output", ctx.outputs.result)

    ctx.actions.run(
        executable = ctx.executable._kustomize,
        arguments = [args],
        inputs = kustomization.transitive_resources,
        tools = [ctx.executable._helm] if kustomization.requires_helm else [],
        outputs = [ctx.outputs.result],
        # Allow inclusion of "--action_env" variables when they're
        # likely to be significant:
        use_default_shell_env = len(ctx.attr.env_exports) > 0,
        mnemonic = "KustomizeBuild",
        progress_message = "Building the \"{}\" kustomization target {}".format(ctx.label.name, kustomization.root),
    )

_kustomized_resources = rule(
    attrs = _kustomized_resources_attrs,
    implementation = _kustomized_resources_impl,
)

def kustomized_resources(name, **kwargs):
    result = kwargs.pop("result", name + ".yaml")

    _kustomized_resources(
        name = name,
        result = result,
        **kwargs
    )
