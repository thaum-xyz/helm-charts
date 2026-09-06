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

| Chart | Purpose | Consumed by |
| --- | --- | --- |
| [`cnpg-database`](charts/cnpg-database) | CloudNativePG cluster with barman-cloud object store, scheduled backups, Doppler-backed credentials and backup alerting | every Postgres database in the cluster |
| [`lvm-diskprep`](charts/lvm-diskprep) | Prepares LVM node disks for CSI stacks via privileged DaemonSets and textfile metrics | `topolvm-system` |

### Removed: `versitygw`

Deleted on 2026-09-06. It had no consumer anywhere: no reference in `ankhmorpork`
or any sibling repository, and no HelmRelease in the live cluster. All three
gateways (`cnpg-system`, `longhorn-system`, `datalake-logs`) run
[upstream's chart][up] at v0.3.5, whose values are shaped completely differently
— `gateway.backend` and `persistence` rather than this chart's `storage.data`
and `bucketName`. It never left 0.1.0 and was a superseded first attempt.

The published artifact `oci://ghcr.io/thaum-xyz/helm-charts/versitygw:0.1.0` is
deliberately **left in place**. Deleting a pushed OCI tag breaks anyone who
already pulled it, and it buys nothing — the release job only pushes charts
whose `version` changed, so a removed chart directory simply stops being
republished. Restore the source with `git checkout f788e81 -- charts/versitygw`
if it is ever wanted.

[up]: https://github.com/versity/versitygw/tree/main/chart

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

Coverage is uneven and the generated tables show exactly where — `cnpg-database`
documents 35 of 66 values, `lvm-diskprep` none of 14. A value without a `# --`
comment still appears in the table, with an empty description.

## Releases

Pushing to `main` releases any chart whose `version` in `Chart.yaml` changed.
Bump it in the same pull request as the change.
