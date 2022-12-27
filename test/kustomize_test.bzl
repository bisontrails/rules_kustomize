load(
    "//kustomize:kustomize.bzl",
    "kustomization",
    "kustomized_resources",
)

def kustomize_test(
        name,
        srcs = [],
        deps = [],
        kustomization_file = None,
        golden_file = None,
        requires_helm = False,
        **kwargs):
    kustomization(
        name = name,
        deps = deps,
        file = kustomization_file or "testdata/%s/kustomization.yaml" % name,
        requires_helm = requires_helm,
        srcs = srcs,
    )

    genrule_name = name + "_resources"
    generated_resources_file = genrule_name + ".yaml"

    kustomized_resources(
        name = genrule_name,
        kustomization = name,
        # Allow running these basic tests in CI with fewer
        # requirements imposed on the host machines, trusting that the
        # tests don't attempt anything unsafe against which kustomize
        # defends by default.
        load_restrictor = "None",
        result = generated_resources_file,
        **kwargs
    )

    if not golden_file:
        golden_file = "testdata/%s/golden.yaml" % name

    native.sh_test(
        name = name + "_test",
        srcs = ["diff-test-runner"],
        args = [
            "$(location %s)" % golden_file,
            "$(location %s)" % generated_resources_file,
        ],
        data = [
            generated_resources_file,
            golden_file,
        ],
        size = "small",
    )
