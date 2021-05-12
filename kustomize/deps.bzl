load(
    "//kustomize/private:repositories.bzl",
    _kustomize_rules_dependencies = "kustomize_rules_dependencies",
)
load(
    "//kustomize/private:tools.bzl",
    _helm_register_tool = "helm_register_tool",
    _kustomize_register_tool = "kustomize_register_tool",
)

helm_register_tool = _helm_register_tool
kustomize_register_tool = _kustomize_register_tool
kustomize_rules_dependencies = _kustomize_rules_dependencies
