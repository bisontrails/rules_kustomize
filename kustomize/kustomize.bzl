KustomizationInfo = provider(
    doc = "Kustomization root summary",
    fields = {
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
    "srcs": attr.label_list(
        doc = "Files referenced as resources for this kustomization.",
        allow_files = True,
    ),
}

def _kustomization_impl(ctx):
    return [
        KustomizationInfo(
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

def _helm_tool_if_enabled(enable_helm):
    return Label("//kustomize:helm") if enable_helm else None

_kustomized_resources_attrs = {
    "enable_alpha_plugins": attr.bool(
        doc = "Enable kustomize plugins.",
    ),
    "enable_exec": attr.bool(
        doc = "Enable support for exec functions (raw executables).",
    ),
    "enable_helm": attr.bool(
        doc = "Enable use of the Helm chart inflator generator.",
    ),
    "enable_managed_by_label": attr.bool(
        doc = "Enable adding the 'app.kubernetes.io/managed-by' label to objects.",
    ),
    "enable_starlark_functions": attr.bool(
        doc = "Enable support for Starlark functions.",
    ),
    "env_bindings": attr.string_dict(
        doc = "Names and values of environment variables to be used by functions.",
    ),
    "env_exports": attr.string_list(
        doc = "Names of exported environment variables to be used by functions.",
    ),
    "_helm": attr.label(
        doc = "Helm tool to use for inflating Helm charts.",
        default = _helm_tool_if_enabled,
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
        doc = "The built result, with a YAML stream of KRM resources in separate documents.",
        mandatory = True,
    ),
}

def _kustomized_resources_impl(ctx):
    kustomization = ctx.attr.kustomization[KustomizationInfo]
    args = ctx.actions.args()
    args.add("build")
    args.add(kustomization.root)
    if ctx.attr.enable_alpha_plugins:
        args.add("--enable-alpha-plugins")
    if ctx.attr.enable_exec:
        args.add("--enable-exec")
    if ctx.attr.enable_helm:
        args.add("--enable-helm")
        args.add("--helm-command", ctx.executable._helm.path)
    if ctx.attr.enable_managed_by_label:
        args.add("--enable-managedby-label")
    if ctx.attr.enable_starlark_functions:
        args.add("--enable-star")

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
        tools = [ctx.executable._helm] if ctx.attr.enable_helm else [],
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
