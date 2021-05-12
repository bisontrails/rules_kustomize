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

def _maybe_github_revision(name, organization, repository, revision, uses_v_prefix = False, **kwargs):
    prefix_component = revision
    if uses_v_prefix:
        prefix_component = prefix_component.lstrip("v")
    _maybe(
        http_archive,
        name = name,
        strip_prefix = "{}-{}".format(repository, prefix_component),
        urls = [
            "https://github.com/{}/{}/archive/{}.zip".format(
                organization,
                repository,
                revision,
            ),
        ],
        **kwargs
    )

def kustomize_rules_dependencies():
    # None yet.
    pass
