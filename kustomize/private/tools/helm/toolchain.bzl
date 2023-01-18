_TOOLS_BY_RELEASE = {
    "v3.11.0": {
        struct(os = "darwin", arch = "amd64"): "5a3d13545a302eb2623236353ccd3eaa01150c869f4d7f7a635073847fd7d932",
        struct(os = "linux", arch = "amd64"): "6c3440d829a56071a4386dd3ce6254eab113bc9b1fe924a6ee99f7ff869b9e0b",
        struct(os = "linux", arch = "arm64"): "57d36ff801ce8c0201ce9917c5a2d3b4da33e5d4ea154320962c7d6fb13e1f2c",
        struct(os = "windows", arch = "amd64"): "55477fa4295fb3043835397a19e99a138bb4859fbe7cd2d099de28df9d8786f1",
    },
    "v3.10.3": {
        struct(os = "darwin", arch = "amd64"): "77a94ebd37eab4d14aceaf30a372348917830358430fcd7e09761eed69f08be5",
        struct(os = "linux", arch = "amd64"): "950439759ece902157cf915b209b8d694e6f675eaab5099fb7894f30eeaee9a2",
        struct(os = "linux", arch = "arm64"): "260cda5ff2ed5d01dd0fd6e7e09bc80126e00d8bdc55f3269d05129e32f6f99d",
        struct(os = "windows", arch = "amd64"): "5d97aa26830c1cd6c520815255882f148040587fd7cdddb61ef66e4c081566e0",
    },
    "v3.9.2": {
        struct(os = "darwin", arch = "amd64"): "35d7ff8bea561831d78dce8f7bf614a7ffbcad3ff88d4c2f06a51bfa51c017e2",
        struct(os = "linux", arch = "amd64"): "3f5be38068a1829670440ccf00b3b6656fd90d0d9cfd4367539f3b13e4c20531",
        struct(os = "linux", arch = "arm64"): "e4e2f9aad786042d903534e3131bc5300d245c24bbadf64fc46cca1728051dbc",
        struct(os = "windows", arch = "amd64"): "d0d98a2a1f4794fcfc437000f89d337dc9278b6b7672f30e164f96c9413a7a74",
    },
}

_DEFAULT_TOOL_VERSION = "v3.11.0"

def known_release_versions():
    return _TOOLS_BY_RELEASE.keys()

HelmInfo = provider(
    doc = "Details pertaining to the Helm toolchain.",
    fields = {
        "tool": "Helm tool to invoke",
        "version": "This tool's released version name",
    },
)

HelmToolInfo = provider(
    doc = "Details pertaining to the Helm tool.",
    fields = {
        "binary": "Helm tool to invoke",
        "version": "This tool's released version name",
    },
)

def _helm_tool_impl(ctx):
    return [HelmToolInfo(
        binary = ctx.executable.binary,
        version = ctx.attr.version,
    )]

helm_tool = rule(
    implementation = _helm_tool_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = "Helm tool to invoke",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    },
)

def _toolchain_impl(ctx):
    tool = ctx.attr.tool[HelmToolInfo]
    toolchain_info = platform_common.ToolchainInfo(
        helminfo = HelmInfo(
            tool = tool.binary,
            version = tool.version,
        ),
    )
    return [toolchain_info]

helm_toolchain = rule(
    implementation = _toolchain_impl,
    attrs = {
        "tool": attr.label(
            mandatory = True,
            providers = [HelmToolInfo],
            cfg = "exec",
            doc = "Helm tool to use for inflating Helm charts.",
        ),
    },
)

# buildifier: disable=unnamed-macro
def declare_helm_toolchains(helm_tool):
    for version, platforms in _TOOLS_BY_RELEASE.items():
        for platform in platforms.keys():
            helm_toolchain(
                name = "{}_{}_{}".format(platform.os, platform.arch, version),
                tool = helm_tool,
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

_MODULE_REPOSITORY_NAME = "rules_kustomize"
_CONTAINING_PACKAGE_PREFIX = "//kustomize/private/tools/helm"

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
        fail('No Helm tool is available for OS "{}" and CPU architecture "{}" at version {}'.format(os, arch, version))
    ctx.report_progress('Downloading Helm tool for OS "{}" and CPU architecture "{}" at version {}.'.format(os, arch, version))
    ctx.download_and_extract(
        url = "https://get.helm.sh/helm-{}-{}-{}.{}".format(
            version,
            os,
            arch,
            "zip" if os == "windows" else "tar.gz",
        ),
        stripPrefix = "{}-{}".format(os, arch),
        sha256 = sha256sum,
    )

    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.tool.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": "@{}{}".format(_MODULE_REPOSITORY_NAME, _CONTAINING_PACKAGE_PREFIX),
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

# buildifier: disable=unnamed-macro
def declare_bazel_toolchains(version, toolchain_prefix):
    native.constraint_value(
        name = version,
        constraint_setting = "{}:tool_version".format(_CONTAINING_PACKAGE_PREFIX),
    )
    constraint_value_prefix = "@{}//kustomize/private/tools".format(_MODULE_REPOSITORY_NAME)
    for platform in _TOOLS_BY_RELEASE[version].keys():
        native.toolchain(
            name = "{}_{}_{}_toolchain".format(platform.os, platform.arch, version),
            exec_compatible_with = [
                "{}:cpu_{}".format(constraint_value_prefix, platform.arch),
                "{}:os_{}".format(constraint_value_prefix, platform.os),
            ],
            toolchain = toolchain_prefix + (":{}_{}_{}".format(platform.os, platform.arch, version)),
            toolchain_type = "@{}//tools/helm:toolchain_type".format(_MODULE_REPOSITORY_NAME),
        )

def _toolchains_impl(ctx):
    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.toolchains.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": "@{}{}".format(_MODULE_REPOSITORY_NAME, _CONTAINING_PACKAGE_PREFIX),
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
