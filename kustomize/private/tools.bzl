load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
    "v3.9.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "7e5a2f2a6696acf278ea17401ade5c35430e2caa57f67d4aa99c607edcc08f5e",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "1484ffb0c7a608d8069470f48b88d729e88c41a1b6602f145231e8ea7b43b50a",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "bcdc6c68dacfabeeb6963dc2e6761e2e87026ffd9ea1cde266ee36841e7c6e6a",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "631d333bce5f2274c00af753d54bb62886cdb17a958d2aff698c196612c9e8cb",
        },
    ],
    "v3.8.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "3b6d87d360a51bf0f2344edd54e3580a8e8de2c4a4fd92eccef3e811f7e81bb3",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "d643f48fe28eeb47ff68a1a7a26fc5142f348d02c8bc38d699674016716f61cd",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "dbf5118259717d86c57d379317402ed66016c642cc0d684f3505da6f194b760d",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "a75003fc692131652d3bd218dd4007692390a1dd156f11fd7668e389bdd8f765",
        },
    ],
}

_kustomize_releases = {
    "v4.5.6": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "76fbaad14142bd532d6a6a7912c6b1e48e427fb20659f172ffd4232d1d430b78",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "6802d54917eb5887f9c71031c59e6845c1a490c13881b050ea6959b714b4a432",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "3b66709c7692c5ccfdcb2f4dd383e7aa622b451b046f2197b59033f16457b3b3",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "4974359500e8315e5e00be6cc65383872723313f96e2cf9f30971d087a2877a5",
        },
    ],
    "v4.5.5": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "f604eaf1083659cd46aaffcc81bf13351a76a2d245823e2345dbb8b840622bde",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "bba81aa61dba057db1d5abeddf1e522b568b2d906ab67a5c80935e97302c8773",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "c491191b81c97ddebc4844f9254683ecfc80f40dfb15510433cbfdaeb86627c3",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "a72d7e5bbce1388c829d17208c34bf11df69215e7e496e05d8156a0d44b7de3d",
        },
    ],
}

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `native.git_repository`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def helm_register_tool(version = "v3.9.0"):
    for platform in _helm_releases[version]:
        suffix = "tar.gz"
        if platform["os"] == "windows":
            suffix = "zip"
        _maybe(
            http_archive,
            name = "helm_tool_%s_%s" % (platform["os"], platform["arch"]),
            build_file_content = """
filegroup(
    name = "binary",
    srcs = ["helm%s"],
    visibility = ["//visibility:public"],
)
""" % (".exe" if platform["os"] == "windows" else ""),
            strip_prefix = "%s-%s" % (platform["os"], platform["arch"]),
            url = "https://get.helm.sh/helm-%s-%s-%s.%s" % (version, platform["os"], platform["arch"], suffix),
            sha256 = platform["sha256"],
        )

def kustomize_register_tool(version = "v4.5.6"):
    for platform in _kustomize_releases[version]:
        _maybe(
            http_archive,
            name = "kustomize_tool_%s_%s" % (platform["os"], platform["arch"]),
            build_file_content = """
filegroup(
    name = "binary",
    srcs = ["kustomize%s"],
    visibility = ["//visibility:public"],
)
""" % (".exe" if platform["os"] == "windows" else ""),
            url = "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/%s/kustomize_%s_%s_%s.tar.gz" % (version, version, platform["os"], platform["arch"]),
            sha256 = platform["sha256"],
        )
