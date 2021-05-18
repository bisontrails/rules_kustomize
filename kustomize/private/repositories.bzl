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

def _maybe_github_revision(name, organization, repository, revision, extension = "zip", strip_prefix = True, uses_v_prefix = False, **kwargs):
    prefix_component = revision
    if uses_v_prefix:
        prefix_component = prefix_component.lstrip("v")
    _maybe(
        http_archive,
        name = name,
        strip_prefix = "{}-{}".format(repository, prefix_component) if strip_prefix else "",
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
    _maybe_github_revision(
        name = "bazel_skylib",
        organization = "bazelbuild",
        repository = "bazel-skylib",
        extension = "tar.gz",
        revision = "1.0.3",
        sha256 = "7ac0fa88c0c4ad6f5b9ffb5e09ef81e235492c873659e6bb99efb89d11246bcb",
    )
