load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
    "v3.7.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "3a9efe337c61a61b3e160da919ac7af8cded8945b75706e401f3655a89d53ef5",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "6cd6cad4b97e10c33c978ff3ac97bb42b68f79766f1d2284cfd62ec04cd177f4",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "57875be56f981d11957205986a57c07432e54d0b282624d68b1aeac16be70704",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "e057f24032a6b5602edccfdf8fa191568471fce29aada86d6f7f46fc611a3258",
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
    "v4.4.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "f0e55366239464546f9870489cee50764d87ebdd07f7402cf2622e5e8dc77ac1",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "bf3a0d7409d9ce6a4a393ba61289047b4cb875a36ece1ec94b36924a9ccbaa0f",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "f38032c5fa58dc05b406702611af82087bc02ba09d450a3c00b217bf94c6f011",
        },
        # See https://github.com/kubernetes-sigs/kustomize/issues/4028
        # for why a Windows build is unavailable for this version.
    ],
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

def kustomize_register_tool(version = "v4.4.0"):
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
