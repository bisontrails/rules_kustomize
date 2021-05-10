load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
    "v3.5.4": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "072c40c743d30efdb8231ca03bab55caee7935e52175e42271a0c3bc37ec0b7b",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "a8ddb4e30435b5fd45308ecce5eaad676d64a5de9c89660b56face3fe990b318",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "9db01522150a83a5d65b420171147448d8396c142d2c91af95e5ee77c1694176",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "830da2a8fba060ceff95486b3166b11c517035092e213f8d775be4ae2f7c13e0",
        },
    ],
}

_kustomize_releases = {
    "v4.1.2": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "08bf3888391a526d247aead55b6bd940574bba238d9d32aa40c0adb4998f812e",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "4efb7d0dadba7fab5191c680fcb342c2b6f252f230019cf9cffd5e4b0cad1d12",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "d4b0ababb06d7208b439c48c5dadf979433f062ee7131203f6a94ce1159c9d5e",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "6074f536a4ded829cc56e75078932836a1a8a5bd154d82c1470999128022b2ed",
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

def helm_register_tool(version = "v3.5.4"):
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

def kustomize_register_tool(version = "v4.1.2"):
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
