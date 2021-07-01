load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
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
    "v3.6.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "7f6bcf15e5c828504dddbe733813a6d73e41abf28d649e7b9d698c4a77d412dd",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "0a9c80b0f211791d6a9d36022abd0d6fd125139abe6d1dcf4c5bf3bc9dcec9c8",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "8a16f23866b1e74b347bcdd7f8731ebcfa37f35fc27c75dd29b13e87aed8484c",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "4e2a5303c551d7836b289fa1869bf89f6d672fe8da078d25b45ede0fb3fffbfe",
        },
    ],
}

_kustomize_releases = {
    "v4.1.3": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "f1e54fdb659a68e5ec0a65aa52868bcc32b18fd3bc2b545db890ba261d3781c4",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "f028cd2b675d215572d54634311777aa475eb5612fb8a70d84b957c4a27a861e",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "4c5073f4b25bd427ed6c0efa7377e2422fe58b8629c349308eaf7489fb9b71cd",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "67a21b674a8dad5e027224c3426e496028e10a65e779e950d07e5d6d8c1d9d2d",
        },
    ],
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

def helm_register_tool(version = "v3.6.2"):
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

def kustomize_register_tool(version = "v4.1.3"):
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
