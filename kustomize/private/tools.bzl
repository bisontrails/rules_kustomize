load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
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
    "v3.6.2": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "81a94d2877326012b99ac0737517501e5ed69bb4987884e7f2d0887ad27895a9",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "f3a4be96b8a3b61b14eec1a35072e1d6e695352e7a08751775abf77861a0bf54",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "957031f3c8cf21359065817c15c5226cb3082cac33547542a37cf3425f9fdcd5",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "71078748101de3f2df40b25031e4b7aa4bdf760ff7bcc6d3f503f988d24bd2c4",
        },
    ],
    "v3.6.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "f5e49aac89701162871e576ebd32506060e43a470da1fcb4b8e4118dc3512913",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "c64f2c7b1d00c5328b164cea4bbd5e0752c103193037173c9eadea9d6a57eddb",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "a044b370d1b6e65b7d8d0aa7da4d11e4f406ec5b56af3a2f5bec09eb00c290fc",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "d46805bf24d4c93c5ccc9af2d49903e3a80771366d0c59ad6d18187450d888d0",
        },
    ],
}

_kustomize_releases = {
    "v4.3.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "77898f8b7c37e3ba0c555b4b7c6d0e3301127fa0de7ade6a36ed767ca1715643",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "d34818d2b5d52c2688bce0e10f7965aea1a362611c4f1ddafd95c4d90cb63319",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "59de4c27c5468f9c160d97576fbdb42a732f15569f68aacdfa96a614500f33a2",
        },
        # See https://github.com/kubernetes-sigs/kustomize/issues/4028
        # for why a Windows build is unavailable for this version.
    ],
    "v4.2.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "808d86fc15cec9226dd8b6440f39cfa8e8e31452efc70fb2f35c59529ddebfbf",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "220dd03dcda8e45dc50e4e42b2d71882cbc4c05e0ed863513e67930ecad939eb",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "33f2cf3b5db64c09560c187224e9d29452fde2b7f00f85941604fc75d9769e4a",
        },
        # See https://github.com/kubernetes-sigs/kustomize/issues/4028
        # for why a Windows build is unavailable for this version.
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

def helm_register_tool(version = "v3.6.3"):
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

def kustomize_register_tool(version = "v4.3.0"):
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
