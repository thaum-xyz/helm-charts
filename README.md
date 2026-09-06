# helm-charts

Helm charts for the [thaum.xyz](https://github.com/thaum-xyz) cluster, published
to `oci://ghcr.io/thaum-xyz/helm-charts`.

Split out of [ankhmorpork][a] so chart testing and releases have their own CI,
not because the charts have an audience of their own. The cluster documentation
lives at [docs.thaum.xyz][docs]; what belongs *here* is whatever a change to a
chart would invalidate — which in practice means the values reference, and that
is generated.

[a]: https://github.com/thaum-xyz/ankhmorpork
[docs]: https://docs.thaum.xyz/

## Charts

| Chart | Purpose |
| --- | --- |
| [`cnpg-database`](charts/cnpg-database) | CloudNativePG cluster with barman-cloud object store, scheduled backups, Doppler-backed credentials and backup alerting |
| [`lvm-diskprep`](charts/lvm-diskprep) | Prepares LVM node disks for CSI stacks via privileged DaemonSets and textfile metrics |

Which components deploy these is recorded in the [cluster documentation][docs]
instead, where a change to the cluster is what invalidates it.

## Values documentation

Each chart's `README.md` is **generated** from its `Chart.yaml` and the `# --`
comments in its `values.yaml` — do not edit them by hand.

```bash
make docs        # regenerate
make docs-check  # fail if they are out of date
```

CI runs `docs-check` on every pull request, so a values change that does not
regenerate its README fails the build. The point is that the reference cannot
drift from the chart: it is invalidated by, and updated in, the same commit.

A value with no `# --` comment still appears in its chart's table with an empty
description, so the generated tables double as the record of what is still
undocumented.

## Releases

Pushing to `main` releases any chart whose `version` in `Chart.yaml` changed.
Bump it in the same pull request as the change.
