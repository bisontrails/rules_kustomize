load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
    "v3.7.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "72dc714911e9a1978e1446fedead6c85b777a3972439285fdf2041aeee0ddfb8",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "1fb98a60ba65a47f6c47727fd15eb4bdf31dc5940b41e359759eab707d0f5742",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "0e2961501ae89936cb03c42bce262df210fb30672422c22ada198252de9d1bc8",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "413ff349b8c0e643bb99267f903f2f90a125314668207dd9fe1d6aba8ede217f",
        },
    ],
    "v3.7.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "0bf671be69563a0c2b4253c393bed271fab90a4aa9321d09685a781f583b5c9d",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "096e30f54c3ccdabe30a8093f8e128dba76bb67af697b85db6ed0453a2701bf9",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "03bf55435b4ebef739f862334bdfbf7b7eed714b94340a22298c485b6626aaca",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "cf6dd076898e2dc1e7f4af593d011f99a9de353b6a2d019731dbc254a1ec880e",
        },
    ],
    "v3.6.3": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "84a1ff17dd03340652d96e8be5172a921c97825fd278a2113c8233a4e8db5236",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "6fe647628bc27e7ae77d015da4d5e1c63024f673062ac7bc11453ccc55657713",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "797d2abd603a2646f2fb9c3fabba46f2fabae5cbd1eb87c20956ec5b4a2fc634",
        },
    ],
}

_kustomize_releases = {
    "v4.5.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "72dc714911e9a1978e1446fedead6c85b777a3972439285fdf2041aeee0ddfb8",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "1fb98a60ba65a47f6c47727fd15eb4bdf31dc5940b41e359759eab707d0f5742",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "0e2961501ae89936cb03c42bce262df210fb30672422c22ada198252de9d1bc8",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "413ff349b8c0e643bb99267f903f2f90a125314668207dd9fe1d6aba8ede217f",
        },
    ],
    "v4.4.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "1b0eba143cd684f98341d58100c17a2dfb9658375302fe38d725752ea92012ac",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "2d5927efec40ba32a121c49f6df9955b8b8a296ef1dec4515a46fc84df158798",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "8e54066784ca38e451035dad5de985bfdbdcf55838603576ab58d880883550b5",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "3e1b11456a81924c16c8df89653ed8597f0c446f9f56628f25f8f1abb2fe0c44",
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

def helm_register_tool(version = "v3.7.1"):
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

def kustomize_register_tool(version = "v4.5.0"):
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
