_TOOLS_BY_RELEASE = {
    "v4.5.7": {
        struct(os = "darwin", arch = "amd64"): "6fd57e78ed0c06b5bdd82750c5dc6d0f992a7b926d114fe94be46d7a7e32b63a",
        struct(os = "linux", arch = "amd64"): "701e3c4bfa14e4c520d481fdf7131f902531bfc002cb5062dcf31263a09c70c9",
        struct(os = "linux", arch = "arm64"): "65665b39297cc73c13918f05bbe8450d17556f0acd16242a339271e14861df67",
        struct(os = "windows", arch = "amd64"): "79af25f97bb10df999e540def94e876555696c5fe42d4c93647e28f83b1efc55",
    },
    "v4.5.5": {
        struct(os = "darwin", arch = "amd64"): "f604eaf1083659cd46aaffcc81bf13351a76a2d245823e2345dbb8b840622bde",
        struct(os = "linux", arch = "amd64"): "bba81aa61dba057db1d5abeddf1e522b568b2d906ab67a5c80935e97302c8773",
        struct(os = "linux", arch = "arm64"): "c491191b81c97ddebc4844f9254683ecfc80f40dfb15510433cbfdaeb86627c3",
        struct(os = "windows", arch = "amd64"): "a72d7e5bbce1388c829d17208c34bf11df69215e7e496e05d8156a0d44b7de3d",
    },
}

_DEFAULT_TOOL_VERSION = "v4.5.7"

def known_release_versions():
    return _TOOLS_BY_RELEASE.keys()

KustomizeInfo = provider(
    doc = "Details pertaining to the Kustomize toolchain.",
    fields = {
        "tool": "Kustomize tool to invoke",
        "version": "This tool's released version name",
    },
)

KustomizeToolInfo = provider(
    doc = "Details pertaining to the Kustomize tool.",
    fields = {
        "binary": "Kustomize tool to invoke",
        "version": "This tool's released version name",
    },
)

def _kustomize_tool_impl(ctx):
    return [KustomizeToolInfo(
        binary = ctx.executable.binary,
        version = ctx.attr.version,
    )]

kustomize_tool = rule(
    implementation = _kustomize_tool_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = "Kustomize tool to invoke",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    },
)

def _toolchain_impl(ctx):
    tool = ctx.attr.tool[KustomizeToolInfo]
    toolchain_info = platform_common.ToolchainInfo(
        kustomizeinfo = KustomizeInfo(
            tool = tool.binary,
            version = tool.version,
        ),
    )
    return [toolchain_info]

kustomize_toolchain = rule(
    implementation = _toolchain_impl,
    attrs = {
        "tool": attr.label(
            mandatory = True,
            providers = [KustomizeToolInfo],
            cfg = "exec",
            doc = "Kustomize tool to use for building kustomizations.",
        ),
    },
)

# buildifier: disable=unnamed-macro
def declare_kustomize_toolchains(kustomize_tool):
    for version, platforms in _TOOLS_BY_RELEASE.items():
        for platform in platforms.keys():
            kustomize_toolchain(
                name = "{}_{}_{}".format(platform.os, platform.arch, version),
                tool = kustomize_tool,
            )

def _translate_host_platform(ctx):
    # NB: This is adapted from rules_go's "_detect_host_platform" function.
    os = ctx.os.name
    if os == "mac os x":
        os = "darwin"
    elif os.startswith("windows"):
        os = "windows"

    arch = ctx.os.arch
    if arch == "aarch64":
        arch = "arm64"
    elif arch == "x86_64":
        arch = "amd64"

    return os, arch

def _download_tool_impl(ctx):
    if not ctx.attr.arch and not ctx.attr.os:
        os, arch = _translate_host_platform(ctx)
    else:
        if not ctx.attr.arch:
            fail('"os" is set but "arch" is not')
        if not ctx.attr.os:
            fail('"arch" is set but "os" is not')
        os, arch = ctx.attr.os, ctx.attr.arch
    version = ctx.attr.version

    sha256sum = _TOOLS_BY_RELEASE[version][struct(os = os, arch = arch)]
    if not sha256sum:
        fail('No Kustomize tool is available for OS "{}" and CPU architecture "{}" at version {}'.format(os, arch, version))
    ctx.report_progress('Downloading Kustomize tool for OS "{}" and CPU architecture "{}" at version {}.'.format(os, arch, version))
    ctx.download_and_extract(
        url = "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F{version}/kustomize_{version}_{os}_{arch}.tar.gz".format(
            version = version,
            os = os,
            arch = arch,
        ),
        sha256 = sha256sum,
    )

    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.tool.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": _CONTAINING_PACKAGE_PREFIX,
            "{extension}": ".exe" if os == "windows" else "",
            "{version}": version,
        },
    )
    return None

_download_tool = repository_rule(
    implementation = _download_tool_impl,
    attrs = {
        "arch": attr.string(),
        "os": attr.string(),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

_CONTAINING_REPOSITORY_NAME = "co_bisontrails_rules_kustomize"
_CONTAINING_PACKAGE_PREFIX = "@{}//kustomize/private/tools/kustomize".format(_CONTAINING_REPOSITORY_NAME)

# buildifier: disable=unnamed-macro
def declare_bazel_toolchains(version, toolchain_prefix):
    native.constraint_value(
        name = version,
        constraint_setting = "{}:tool_version".format(_CONTAINING_PACKAGE_PREFIX),
    )
    constraint_value_prefix = "@{}//kustomize/private/tools".format(_CONTAINING_REPOSITORY_NAME)
    for platform in _TOOLS_BY_RELEASE[version].keys():
        native.toolchain(
            name = "{}_{}_{}_toolchain".format(platform.os, platform.arch, version),
            exec_compatible_with = [
                "{}:cpu_{}".format(constraint_value_prefix, platform.arch),
                "{}:os_{}".format(constraint_value_prefix, platform.os),
            ],
            toolchain = toolchain_prefix + (":{}_{}_{}".format(platform.os, platform.arch, version)),
            toolchain_type = "@{}//tools/kustomize:toolchain_type".format(_CONTAINING_REPOSITORY_NAME),
        )

def _toolchains_impl(ctx):
    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.toolchains.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": _CONTAINING_PACKAGE_PREFIX,
            "{tool_repo}": ctx.attr.tool_repo,
            "{version}": ctx.attr.version,
        },
    )

_toolchains_repo = repository_rule(
    implementation = _toolchains_impl,
    attrs = {
        "tool_repo": attr.string(mandatory = True),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

def download_tool(name, version = None):
    _download_tool(
        name = name,
        version = version,
    )
    _toolchains_repo(
        name = name + "_toolchains",
        tool_repo = name,
        version = version,
    )
