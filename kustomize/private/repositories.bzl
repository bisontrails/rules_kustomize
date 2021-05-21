load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `native.git_repository`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def _maybe_github_revision(name, organization, repository, revision, extension = "zip", prefix_override = None, uses_v_prefix = False, **kwargs):
    stripped_prefix = prefix_override
    if prefix_override == None:
        prefix_component = revision
        if uses_v_prefix:
            prefix_component = prefix_component.lstrip("v")
        stripped_prefix = "{}-{}".format(repository, prefix_component)
    _maybe(
        http_archive,
        name = name,
        strip_prefix = stripped_prefix,
        urls = [
            "https://github.com/{}/{}/archive/{}.{}".format(
                organization,
                repository,
                revision,
                extension,
            ),
        ],
        **kwargs
    )

def kustomize_rules_dependencies():
    http_archive(
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    )
