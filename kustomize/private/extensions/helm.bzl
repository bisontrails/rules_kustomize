load(
    "//kustomize/private/tools/helm:toolchain.bzl",
    "download_tool",
    "known_release_versions",
)
load(
    ":download.bzl",
    "make_tag_class",
    "maximal_selected_version",
)

visibility("//kustomize")

def _helm_impl(ctx):
    download_tool(
        name = "helm_tool",
        version = maximal_selected_version(ctx, "Helm"),
    )

helm = module_extension(
    implementation = _helm_impl,
    tag_classes = {
        "download": make_tag_class(known_release_versions()),
    },
)
