load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
    "v3.8.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "532ddd6213891084873e5c2dcafa577f425ca662a6594a3389e288fc48dc2089",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "8408c91e846c5b9ba15eb6b1a5a79fc22dd4d33ac6ea63388e5698d1b2320c8b",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "23e08035dc0106fe4e0bd85800fd795b2b9ecd9f32187aa16c49b0a917105161",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "d52e0cda6c4cc0e0717d5161ca1ba7a8d446437afdbe42b3c565c145ac752888",
        },
    ],
    "v3.7.2": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "5a0738afb1e194853aab00258453be8624e0a1d34fcc3c779989ac8dbcd59436",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "4ae30e48966aba5f807a4e140dad6736ee1a392940101e4d79ffb4ee86200a9e",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "b0214eabbb64791f563bd222d17150ce39bf4e2f5de49f49fdb456ce9ae8162f",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "299165f0af46bece9a61b41305cca8e8d5ec5319a4b694589cd71e6b75aca77e",
        },
    ],
}

_kustomize_releases = {
    "v4.5.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "427d1d32bdde47f3b36a848253d1c936f623ffc4dbe4137c1deadd2c099a9000",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "cc26e18e814fd162dacd5e2a1357aa133fb91589e23a15ccc8b7c163fd259c54",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "4873fb965cad3a646bea4ffc2f2f9189501fe7bc6f0ae8854920593b9ba13d73",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "1b8062331e6af223017d015d6df2b32f8580bf9ed2f9c92bcd718aa371e6e218",
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

def helm_register_tool(version = "v3.8.0"):
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

def kustomize_register_tool(version = "v4.5.1"):
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
