load(
    "@bazel_skylib//lib:paths.bzl",
    "paths",
)

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

def _file_is_derived(f):
    return len(f.root.path) > 0

def _kustomization_impl(ctx):
    k_file = ctx.file.file
    root = k_file.dirname
    if _file_is_derived(k_file):
        root = paths.dirname(k_file.short_path)
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
            root = root,
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
    "_zipper": attr.label(
        default = Label("@bazel_tools//tools/zip:zipper"),
        executable = True,
        allow_single_file = True,
        cfg = "exec",
    ),
    "env_bindings": attr.string_dict(
        doc = "Names and values of environment variables to be used by functions.",
    ),
    "env_exports": attr.string_list(
        doc = "Names of exported environment variables to be used by functions.",
    ),
    "kustomization": attr.label(
        doc = "kustomization to build.",
        mandatory = True,
        providers = [KustomizationInfo],
    ),
    "load_restrictor": attr.string(
        doc = "Control whether kustomizations may load files from outsider their root directory.",
        values = [
            "None",
            "RootOnly",
        ],
        default = "RootOnly",
    ),
    "result": attr.output(
        doc = "The built result, as a YAML stream of KRM resources in separate documents.",
        mandatory = True,
    ),
}

def _make_zip_archive_of(ctx, files):
    zip_manifest_file = ctx.actions.declare_file("{}-manifest".format(ctx.label.name))
    ctx.actions.write(
        zip_manifest_file,
        "".join(["{}={}\n".format(f.short_path, f.path) for f in files]),
    )
    source_zip_file = ctx.actions.declare_file(ctx.label.name + ".zip")

    args = ctx.actions.args()
    args.add("c")
    args.add(source_zip_file.path)
    args.add("@" + zip_manifest_file.path)
    ctx.actions.run(
        executable = ctx.executable._zipper,
        arguments = [args],
        inputs = files + [zip_manifest_file],
        outputs = [source_zip_file],
        mnemonic = "KustomizeCollectSourceZIPFile",
        progress_message = "Collecting source files from kustomized_resources target \"{}\"".format(ctx.label.name),
    )
    return source_zip_file

def _files_are_derived(files):
    for f in files:
        if _file_is_derived(f):
            return True
    return False

_kustomize_toolchain_type = "//tools/kustomize:toolchain_type"
_helm_toolchain_type = "//tools/helm:toolchain_type"

def _kustomized_resources_impl(ctx):
    kustomization = ctx.attr.kustomization[KustomizationInfo]
    kustomize_tool = ctx.toolchains[_kustomize_toolchain_type].kustomizeinfo.tool
    helm_tool = None
    args = ctx.actions.args()
    args.add("build")
    args.add(kustomization.root)
    if kustomization.requires_helm:
        info = ctx.toolchains[_helm_toolchain_type].helminfo
        if not info:
            fail("No Helm toolchain is available; unable to proceed with invoking kustomize without it")
        helm_tool = info.tool
        args.add("--enable-helm")
        args.add("--helm-command", helm_tool.path)
    if kustomization.requires_exec_functions:
        args.add("--enable-exec")
    if kustomization.requires_plugins:
        args.add("--enable-alpha-plugins")
    if kustomization.requires_starlark_functions:
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
    args.add("--output", ctx.outputs.result)

    # Allow inclusion of "--action_env" variables when they're likely to be
    # significant:
    use_default_shell_env = len(ctx.attr.env_exports) > 0
    mnemonic = "KustomizeBuild"
    progress_message = "Building the \"{}\" kustomization target {}".format(ctx.label.name, kustomization.root)

    # In order to allow kustomize to find all the input files in the
    # same directory tree, as opposed to spread among different Bazel
    # "roots" depending on whether the file is derived or not, pack
    # the files into a ZIP archive with their relative paths adjusted,
    # folding together contributions from each of these "roots."
    #
    # If there are no derived files involved, we don't need the
    # intermediary ZIP archive.
    files = kustomization.transitive_resources.to_list()
    if _files_are_derived(files):
        source_zip_file = _make_zip_archive_of(ctx, files)
        ctx.actions.run_shell(
            inputs = [source_zip_file],
            tools = [kustomize_tool] +
                    ([helm_tool] if kustomization.requires_helm else []),
            outputs = [ctx.outputs.result],
            command = """\
kustomize=$1; shift
source_zip_file=$1; shift

unzip -q "${source_zip_file}"

"${kustomize}" "${@}"
""",
            arguments = [
                kustomize_tool.path,
                source_zip_file.path,
                args,
            ],
            use_default_shell_env = use_default_shell_env,
            mnemonic = mnemonic,
            progress_message = progress_message,
        )
    else:
        ctx.actions.run(
            executable = kustomize_tool,
            arguments = [args],
            inputs = kustomization.transitive_resources,
            tools = [helm_tool] if kustomization.requires_helm else [],
            outputs = [ctx.outputs.result],
            use_default_shell_env = use_default_shell_env,
            mnemonic = mnemonic,
            progress_message = progress_message,
        )

_kustomized_resources = rule(
    attrs = _kustomized_resources_attrs,
    implementation = _kustomized_resources_impl,
    toolchains = [
        _kustomize_toolchain_type,
        config_common.toolchain_type(
            _helm_toolchain_type,
            mandatory = False,
        ),
    ],
)

def kustomized_resources(name, **kwargs):
    result = kwargs.pop("result", name + ".yaml")

    _kustomized_resources(
        name = name,
        result = result,
        **kwargs
    )
